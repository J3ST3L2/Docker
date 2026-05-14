#!/usr/bin/env python3
import asyncio
import os
import subprocess
from pathlib import Path

import discord
from discord import app_commands

ALLOWED_USER_ID = int(os.environ["ALLOWED_USER_ID"])
OP_TOKEN_FILE = os.environ.get("OP_TOKEN_FILE", "/etc/1password/jestertek-readonly.token")
BOT_TOKEN_REF = os.environ.get("BOT_TOKEN_REF", "op://JesterTek/Discord Bot/DISCORD_BOT_TOKEN")
SCRIPT_DIR = Path(os.environ.get("SCRIPT_DIR", "/opt/homelab-discord-bot/scripts"))

TARGETS = {
    "arr": SCRIPT_DIR / "redeploy-arr.sh",
    "nms": SCRIPT_DIR / "redeploy-nms.sh",
    "graylog": SCRIPT_DIR / "redeploy-graylog.sh",
    "akvorado": SCRIPT_DIR / "redeploy-akvorado.sh",
}


def read_bot_token() -> str:
    token = Path(OP_TOKEN_FILE).read_text(encoding="utf-8").strip()
    env = os.environ.copy()
    env["OP_SERVICE_ACCOUNT_TOKEN"] = token
    result = subprocess.run(
        ["op", "read", BOT_TOKEN_REF],
        check=True,
        text=True,
        capture_output=True,
        env=env,
        timeout=20,
    )
    return result.stdout.strip()


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


class HomelabBot(discord.Client):
    def __init__(self) -> None:
        intents = discord.Intents.default()
        super().__init__(intents=intents)
        self.tree = app_commands.CommandTree(self)

    async def setup_hook(self) -> None:
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


@bot.event
async def on_ready() -> None:
    print(f"Logged in as {bot.user} ({bot.user.id if bot.user else 'unknown'})", flush=True)


bot.run(read_bot_token())
