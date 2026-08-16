#!/usr/bin/env python3
import asyncio
import json
import os
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Optional, Union

import discord
from discord import app_commands

ALLOWED_USER_ID = int(os.environ["ALLOWED_USER_ID"])
MEDIA_CHANNEL_ID = int(os.environ.get("MEDIA_CHANNEL_ID", "0"))
DISCORD_GUILD_ID = int(os.environ.get("DISCORD_GUILD_ID", "0"))
OP_TOKEN_FILE = os.environ.get("OP_TOKEN_FILE", "/etc/1password/jestertek-readonly.token")
BOT_TOKEN_REF = os.environ.get("BOT_TOKEN_REF", "op://JesterTek/Discord Bot/DISCORD_BOT_TOKEN")
SONARR_API_KEY_REF = os.environ.get("SONARR_API_KEY_REF", "op://JesterTek/ARR Stack/SONARR_API_KEY")
RADARR_API_KEY_REF = os.environ.get("RADARR_API_KEY_REF", "op://JesterTek/ARR Stack/RADARR_API_KEY")
SONARR_URL = os.environ.get("SONARR_URL", "http://10.20.60.13:8989").rstrip("/")
RADARR_URL = os.environ.get("RADARR_URL", "http://10.20.60.13:7878").rstrip("/")
SONARR_ROOT_FOLDER = os.environ.get("SONARR_ROOT_FOLDER", "/tv")
RADARR_ROOT_FOLDER = os.environ.get("RADARR_ROOT_FOLDER", "/movies")
SONARR_QUALITY_PROFILE_ID = int(os.environ.get("SONARR_QUALITY_PROFILE_ID", "1"))
SONARR_LANGUAGE_PROFILE_ID = os.environ.get("SONARR_LANGUAGE_PROFILE_ID", "").strip()
RADARR_QUALITY_PROFILE_ID = int(os.environ.get("RADARR_QUALITY_PROFILE_ID", "1"))
SCRIPT_DIR = Path(os.environ.get("SCRIPT_DIR", "/opt/homelab-discord-bot/scripts"))

TARGETS = {
    "arr": SCRIPT_DIR / "redeploy-arr.sh",
    "nms": SCRIPT_DIR / "redeploy-nms.sh",
    "graylog": SCRIPT_DIR / "redeploy-graylog.sh",
    "akvorado": SCRIPT_DIR / "redeploy-akvorado.sh",
}


def op_read(secret_ref: str) -> str:
    token = Path(OP_TOKEN_FILE).read_text(encoding="utf-8").strip()
    env = os.environ.copy()
    env["OP_SERVICE_ACCOUNT_TOKEN"] = token
    result = subprocess.run(
        ["op", "read", secret_ref],
        check=True,
        text=True,
        capture_output=True,
        env=env,
        timeout=20,
    )
    return result.stdout.strip()


def read_bot_token() -> str:
    return op_read(BOT_TOKEN_REF)


async def run_script(path: Path) -> tuple[int, str]:
    proc = await asyncio.create_subprocess_exec(
        str(path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )
    try:
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=420)
    except asyncio.TimeoutError:
        proc.kill()
        await proc.communicate()
        return 124, "Command timed out."
    output = stdout.decode("utf-8", errors="replace").strip()
    return proc.returncode or 0, output[-1800:]


def allowed(interaction: discord.Interaction) -> bool:
    return bool(interaction.user and interaction.user.id == ALLOWED_USER_ID)


def media_channel_allowed(interaction: discord.Interaction) -> bool:
    return bool(MEDIA_CHANNEL_ID and interaction.channel_id == MEDIA_CHANNEL_ID)


def api_request(
    method: str,
    url: str,
    api_key: str,
    data: Optional[dict] = None,
) -> Union[dict, list]:
    body = None
    headers = {"X-Api-Key": api_key}
    if data is not None:
        body = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            content = resp.read().decode("utf-8")
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as exc:
        content = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{exc.code} {content[:500]}") from exc


def queue_records(base_url: str, api_key: str) -> list:
    queue = api_request("GET", f"{base_url}/api/v3/queue?pageSize=100", api_key)
    if isinstance(queue, dict):
        return queue.get("records", [])
    if isinstance(queue, list):
        return queue
    return []


def history_records(base_url: str, api_key: str, entity: str, entity_id: int) -> list:
    params = urllib.parse.urlencode(
        {
            f"{entity}Id": entity_id,
            "pageSize": 10,
            "sortKey": "date",
            "sortDirection": "descending",
        }
    )
    history = api_request("GET", f"{base_url}/api/v3/history?{params}", api_key)
    if isinstance(history, dict):
        return history.get("records", [])
    if isinstance(history, list):
        return history
    return []


def media_status(base_url: str, api_key: str, entity: str, entity_id: int, title: str) -> str:
    id_key = f"{entity}Id"
    for _ in range(8):
        for record in queue_records(base_url, api_key):
            if record.get(id_key) == entity_id:
                status = record.get("status") or "queued"
                quality = record.get("quality", {}).get("quality", {}).get("name", "unknown quality")
                return f"`{title}` is in the download queue: {status}, {quality}."

        for record in history_records(base_url, api_key, entity, entity_id):
            if record.get("eventType") == "grabbed":
                quality = record.get("quality", {}).get("quality", {}).get("name", "unknown quality")
                return f"`{title}` was grabbed by search: {quality}."

        time.sleep(5)

    return f"`{title}` was added and searched, but no download was grabbed yet."


def sonarr_add(query: str) -> str:
    api_key = op_read(SONARR_API_KEY_REF)
    term = urllib.parse.urlencode({"term": query})
    results = api_request("GET", f"{SONARR_URL}/api/v3/series/lookup?{term}", api_key)
    if not results:
        return f"No Sonarr match found for `{query}`."

    series = results[0]
    payload = {
        "title": series["title"],
        "tvdbId": series["tvdbId"],
        "qualityProfileId": SONARR_QUALITY_PROFILE_ID,
        "titleSlug": series["titleSlug"],
        "images": series.get("images", []),
        "seasons": series.get("seasons", []),
        "rootFolderPath": SONARR_ROOT_FOLDER,
        "monitored": True,
        "seasonFolder": True,
        "seriesType": "standard",
        "addOptions": {"searchForMissingEpisodes": True},
    }
    if SONARR_LANGUAGE_PROFILE_ID:
        payload["languageProfileId"] = int(SONARR_LANGUAGE_PROFILE_ID)

    try:
        added = api_request("POST", f"{SONARR_URL}/api/v3/series", api_key, payload)
    except RuntimeError as exc:
        if "already exists" in str(exc).lower():
            return f"`{series['title']}` already exists in Sonarr."
        raise
    series_id = int(added.get("id", 0)) if isinstance(added, dict) else 0
    if not series_id:
        return f"Added `{series['title']}` to Sonarr and started a search."
    status = media_status(SONARR_URL, api_key, "series", series_id, series["title"])
    return f"Added `{series['title']}` to Sonarr and started a search.\n{status}"


def radarr_add(query: str) -> str:
    api_key = op_read(RADARR_API_KEY_REF)
    term = urllib.parse.urlencode({"term": query})
    results = api_request("GET", f"{RADARR_URL}/api/v3/movie/lookup?{term}", api_key)
    if not results:
        return f"No Radarr match found for `{query}`."

    movie = results[0]
    payload = {
        "title": movie["title"],
        "qualityProfileId": RADARR_QUALITY_PROFILE_ID,
        "titleSlug": movie["titleSlug"],
        "images": movie.get("images", []),
        "tmdbId": movie["tmdbId"],
        "year": movie.get("year"),
        "rootFolderPath": RADARR_ROOT_FOLDER,
        "monitored": True,
        "minimumAvailability": "released",
        "addOptions": {"searchForMovie": True},
    }
    try:
        added = api_request("POST", f"{RADARR_URL}/api/v3/movie", api_key, payload)
    except RuntimeError as exc:
        if "already exists" in str(exc).lower():
            year = movie.get("year", "unknown year")
            return f"`{movie['title']} ({year})` already exists in Radarr."
        raise
    year = movie.get("year", "unknown year")
    title = f"{movie['title']} ({year})"
    movie_id = int(added.get("id", 0)) if isinstance(added, dict) else 0
    if not movie_id:
        return f"Added `{title}` to Radarr and started a search."
    status = media_status(RADARR_URL, api_key, "movie", movie_id, title)
    return f"Added `{title}` to Radarr and started a search.\n{status}"


class HomelabBot(discord.Client):
    def __init__(self) -> None:
        intents = discord.Intents.default()
        super().__init__(intents=intents)
        self.tree = app_commands.CommandTree(self)

    async def setup_hook(self) -> None:
        if DISCORD_GUILD_ID:
            guild = discord.Object(id=DISCORD_GUILD_ID)
            self.tree.copy_global_to(guild=guild)
            try:
                await self.tree.sync(guild=guild)
                print(f"Synced commands to guild {DISCORD_GUILD_ID}", flush=True)
            except discord.Forbidden:
                print(
                    f"Missing access to guild {DISCORD_GUILD_ID}; falling back to global command sync.",
                    flush=True,
                )
                await self.tree.sync()
        else:
            await self.tree.sync()


bot = HomelabBot()


@bot.tree.command(name="redeploy", description="Redeploy a homelab stack from 1Password-rendered secrets.")
@app_commands.describe(target="Stack to redeploy")
@app_commands.choices(
    target=[
        app_commands.Choice(name="arr", value="arr"),
        app_commands.Choice(name="nms", value="nms"),
        app_commands.Choice(name="graylog", value="graylog"),
        app_commands.Choice(name="akvorado", value="akvorado"),
    ]
)
async def redeploy(interaction: discord.Interaction, target: app_commands.Choice[str]) -> None:
    if not allowed(interaction):
        await interaction.response.send_message("Not authorized.", ephemeral=True)
        return

    script = TARGETS[target.value]
    await interaction.response.defer(ephemeral=True, thinking=True)
    code, output = await run_script(script)
    status = "OK" if code == 0 else f"FAILED ({code})"
    await interaction.followup.send(
        f"`/redeploy {target.value}` {status}\n```text\n{output or 'No output.'}\n```",
        ephemeral=True,
    )


@bot.tree.command(name="secrets-test", description="Render secrets for a stack without redeploying it.")
@app_commands.describe(target="Stack to test")
@app_commands.choices(
    target=[
        app_commands.Choice(name="arr", value="arr"),
        app_commands.Choice(name="nms", value="nms"),
        app_commands.Choice(name="graylog", value="graylog"),
        app_commands.Choice(name="akvorado", value="akvorado"),
    ]
)
async def secrets_test(interaction: discord.Interaction, target: app_commands.Choice[str]) -> None:
    if not allowed(interaction):
        await interaction.response.send_message("Not authorized.", ephemeral=True)
        return

    script = SCRIPT_DIR / f"test-{target.value}.sh"
    await interaction.response.defer(ephemeral=True, thinking=True)
    code, output = await run_script(script)
    status = "OK" if code == 0 else f"FAILED ({code})"
    await interaction.followup.send(
        f"`/secrets-test {target.value}` {status}\n```text\n{output or 'No output.'}\n```",
        ephemeral=True,
    )


@bot.tree.command(name="sonarr", description="Add a TV series to Sonarr and search for missing episodes.")
@app_commands.describe(query="Series name, optionally with year")
async def sonarr(interaction: discord.Interaction, query: str) -> None:
    if not media_channel_allowed(interaction):
        await interaction.response.send_message("Use this command in the media download channel.", ephemeral=True)
        return

    await interaction.response.defer(ephemeral=False, thinking=True)
    try:
        output = await asyncio.to_thread(sonarr_add, query.strip())
        await interaction.followup.send(output)
    except Exception as exc:
        await interaction.followup.send(f"Sonarr request failed: `{exc}`", ephemeral=True)


@bot.tree.command(name="radarr", description="Add a movie to Radarr and search for it.")
@app_commands.describe(query="Movie name, optionally with year")
async def radarr(interaction: discord.Interaction, query: str) -> None:
    if not media_channel_allowed(interaction):
        await interaction.response.send_message("Use this command in the media download channel.", ephemeral=True)
        return

    await interaction.response.defer(ephemeral=False, thinking=True)
    try:
        output = await asyncio.to_thread(radarr_add, query.strip())
        await interaction.followup.send(output)
    except Exception as exc:
        await interaction.followup.send(f"Radarr request failed: `{exc}`", ephemeral=True)


@bot.event
async def on_ready() -> None:
    print(f"Logged in as {bot.user} ({bot.user.id if bot.user else 'unknown'})", flush=True)


bot.run(read_bot_token())
