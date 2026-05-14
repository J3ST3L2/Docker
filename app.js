const apps = [
  {
    name: "My Apps",
    url: "https://myapps.jestertek.cc",
    description: "Hosted app dashboard",
    initials: "MA",
    color: "#55c7a4",
  },
  {
    name: "Nginx Proxy Manager",
    url: "https://npm.jestertek.cc",
    description: "Reverse proxy and certificates",
    initials: "NP",
    color: "#63a7ff",
  },
  {
    name: "LibreNMS",
    url: "https://nms.jestertek.cc",
    description: "Network monitoring and alerts",
    initials: "LN",
    color: "#55c7a4",
  },
  {
    name: "Akvorado",
    url: "https://akvorado.jestertek.cc",
    description: "Network flow analytics",
    initials: "AK",
    color: "#5fd0d5",
  },
  {
    name: "Graylog",
    url: "https://graylog.jestertek.cc",
    description: "Centralized logs and search",
    initials: "GL",
    color: "#b58cff",
  },
  {
    name: "Proxmox",
    url: "https://pve.jestertek.cc",
    description: "Virtual machines and containers",
    initials: "PVE",
    color: "#f3b35b",
  },
  {
    name: "PegaProx",
    url: "https://pegaprox.jestertek.cc",
    description: "Secondary Proxmox host",
    initials: "PG",
    color: "#f3b35b",
  },
  {
    name: "Sonarr",
    url: "https://sonarr.jestertek.cc",
    description: "TV series management",
    initials: "SO",
    color: "#63a7ff",
  },
  {
    name: "Radarr",
    url: "https://radarr.jestertek.cc",
    description: "Movie management",
    initials: "RA",
    color: "#f3b35b",
  },
  {
    name: "Prowlarr",
    url: "https://prowlarr.jestertek.cc",
    description: "Indexer management",
    initials: "PR",
    color: "#55c7a4",
  },
  {
    name: "Plex",
    url: "https://plex.jestertek.cc",
    description: "Media server",
    initials: "PX",
    color: "#e6b84d",
  },
  {
    name: "qBittorrent",
    url: "https://download.jestertek.cc",
    description: "Download client",
    initials: "QB",
    color: "#63a7ff",
  },
  {
    name: "Semaphore",
    url: "https://semaphore.jestertek.cc",
    description: "Ansible automation UI",
    initials: "SE",
    color: "#ef6b73",
  },
  {
    name: "NAS",
    url: "https://nas.jestertek.cc",
    description: "Storage and shares",
    initials: "NS",
    color: "#b58cff",
  },
  {
    name: "Proxmox Backup",
    url: "https://pbs.jestertek.cc",
    description: "VM and container backups",
    initials: "PB",
    color: "#55c7a4",
  },
  {
    name: "Proxmox Center",
    url: "https://pcenter.jestertek.cc",
    description: "Proxmox management console",
    initials: "PC",
    color: "#f3b35b",
  },
  {
    name: "Dockge",
    url: "https://dockge.jestertek.cc",
    description: "Docker compose management",
    initials: "DK",
    color: "#63a7ff",
  },
  {
    name: "Uptime Alerts",
    url: "https://alerts.jestertek.cc",
    description: "Service alerting dashboard",
    initials: "AL",
    color: "#ef6b73",
  },
  {
    name: "Albert",
    url: "https://albert.jestertek.cc",
    description: "Hosted service",
    initials: "AB",
    color: "#b58cff",
  },
  {
    name: "UniFi",
    url: "https://unifi.jestertek.cc",
    description: "Network controller",
    initials: "UF",
    color: "#5fd0d5",
  },
  {
    name: "SXG",
    url: "https://sxg.jestertek.cc",
    description: "Hosted service",
    initials: "SX",
    color: "#ef6b73",
  },
];

const appsEl = document.querySelector("#apps");
const countEl = document.querySelector("#count");
const searchEl = document.querySelector("#search");

function hostFromUrl(url) {
  try {
    return new URL(url).host;
  } catch {
    return url;
  }
}

function render(list) {
  countEl.textContent = `${list.length} app${list.length === 1 ? "" : "s"}`;

  if (!list.length) {
    appsEl.innerHTML = '<p class="empty">No matching apps.</p>';
    return;
  }

  appsEl.innerHTML = list
    .map(
      (app) => `
        <a class="app-card" href="${app.url}" target="_blank" rel="noreferrer">
          <div>
            <div class="app-top">
              <span class="mark" style="--mark-bg: ${app.color}22; --mark-fg: ${app.color}">
                ${app.initials}
              </span>
              <p class="name">${app.name}</p>
            </div>
            <p class="description">${app.description}</p>
          </div>
          <span class="url">${hostFromUrl(app.url)}</span>
        </a>
      `,
    )
    .join("");
}

searchEl.addEventListener("input", () => {
  const term = searchEl.value.trim().toLowerCase();
  const filtered = apps.filter((app) =>
    [app.name, app.url, app.description].some((value) =>
      value.toLowerCase().includes(term),
    ),
  );

  render(filtered);
});

render(apps);
