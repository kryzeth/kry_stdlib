import json
import re
from pathlib import Path

index = Path("output/index.html")
search = Path("output/static/search-index.js")

page = index.read_text(encoding="utf-8")
raw = search.read_text(encoding="utf-8")
entries = json.loads(re.search(r"=\s*(\[.*\]);", raw, re.S).group(1))

# Add documented methods to EmmyLua's search index.
methods = {}

for folder in ("class", "module", "global"):
    for path in (Path("output") / folder).glob("*.html"):
        text = path.read_text(encoding="utf-8")
        section = re.search(
            r'<section class="section" id="methods">(.*?)</section>',
            text,
            re.S,
        )
        if not section:
            continue

        for name in re.findall(r'<div class="member[^"]*" id="([^"]+)">', section.group(1)):
            methods.setdefault(name, {
                "name": name,
                "href": f"{folder}/{path.name}#{name}",
                "kind": "method",
            })

entries.extend(methods.values())

search.write_text(
    "window.SEARCH_INDEX = " + json.dumps(entries, separators=(",", ":")) + ";",
    encoding="utf-8",
)

groups = {
    "data": {},
    "runtime": {},
    "shared": {},
}

def add(group, section, entry):
    groups[group].setdefault(section, {})[entry["name"]] = entry

for entry in entries:
    name = entry["name"]

    if "StdLib.Data" in name:
        add("data", "Data", entry)

    elif "StdLib.Event" in name:
        add("runtime", "Event", entry)
    elif "StdLib.Entity" in name or name.startswith("class Entity."):
        add("runtime", "Entity", entry)
    elif "StdLib.Game" in name or name in ("Game", "Things", "ModData"):
        add("runtime", "Game / Scripts", entry)

    elif "StdLib.Area" in name:
        add("shared", "Area", entry)
    elif "StdLib.Misc" in name:
        add("shared", "Misc", entry)
    elif "StdLib.Utils" in name:
        add("shared", "Utils", entry)
    elif "StdLib.Core" in name:
        add("shared", "Core", entry)


def label(name):
    name = re.sub(r"^(class|enum|alias)\s+", "", name)
    return name.split(".")[-1]


def section(title, items):
    links = "".join(
        f'<li><a href="{item["href"]}">{label(name)}</a></li>'
        for name, item in sorted(items.items())
    )
    return f'<div class="kry-subgroup"><h3>{title}</h3><ul>{links}</ul></div>'


def panel(title, group, order=None):
    order = order or group
    body = "".join(section(name, group[name]) for name in order if name in group)
    return f'<section class="kry-panel"><h2>{title}</h2><div class="kry-subgroups">{body}</div></section>'


custom = f"""
<div class="kry-doc-groups">
  <div class="kry-main-groups">
    {panel("Data Stage", groups["data"])}
    {panel("Runtime", groups["runtime"], ("Entity", "Event", "Game / Scripts"))}
  </div>
  {panel("Shared Helpers", groups["shared"], ("Area", "Misc", "Utils", "Core"))}
</div>
"""

style = """
<style>
.kry-main-groups {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.kry-panel {
  border: 1px solid var(--border-color, #d0d7de);
  border-radius: 8px;
  padding: 1rem 1.5rem;
  margin: 1.5rem 0;
}

.kry-panel h2 {
  margin-top: 0;
  padding-bottom: .5rem;
  border-bottom: 1px solid var(--border-color, #d0d7de);
}

.kry-subgroups {
  display: grid;
  gap: 1.25rem;
}

.kry-subgroup h3 {
  margin-bottom: .3rem;
}

.kry-subgroup ul {
  margin-top: 0;
  columns: 2;
}

#shared-helpers .kry-subgroups {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

#shared-helpers .kry-subgroup ul {
  columns: 1;
}

@media (max-width: 1000px) {
  #shared-helpers .kry-subgroups {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 800px) {
  .kry-main-groups {
    grid-template-columns: 1fr;
  }

  .kry-subgroup ul {
    columns: 1;
  }
}

@media (max-width: 600px) {
  #shared-helpers .kry-subgroups {
    grid-template-columns: 1fr;
  }
}
</style>
"""

cards = f"""
<div class="stat-cards">
  <a class="stat-card" href="#data-stage">
    <span class="stat-num">{sum(map(len, groups["data"].values()))}</span>
    <span class="stat-label">Data Stage</span>
  </a>
  <a class="stat-card" href="#runtime">
    <span class="stat-num">{sum(map(len, groups["runtime"].values()))}</span>
    <span class="stat-label">Runtime</span>
  </a>
  <a class="stat-card" href="#shared-helpers">
    <span class="stat-num">{sum(map(len, groups["shared"].values()))}</span>
    <span class="stat-label">Shared Helpers</span>
  </a>
  <a class="stat-card" href="#types">
    <span class="stat-label">Full Reference</span>
  </a>
</div>
"""

page = re.sub(
    r'<div class="stat-cards">.*?</div>',
    cards,
    page,
    count=1,
    flags=re.S,
)

page = page.replace("</head>", style + "</head>", 1)

page = re.sub(
    r'(<header class="hero">.*?</header>)',
    r"\1" + custom,
    page,
    count=1,
    flags=re.S,
)

# Give the panels anchors for the cards.
page = page.replace(
    '<section class="kry-panel"><h2>Data Stage</h2>',
    '<section class="kry-panel" id="data-stage"><h2>Data Stage</h2>',
    1,
)
page = page.replace(
    '<section class="kry-panel"><h2>Runtime</h2>',
    '<section class="kry-panel" id="runtime"><h2>Runtime</h2>',
    1,
)
page = page.replace(
    '<section class="kry-panel"><h2>Shared Helpers</h2>',
    '<section class="kry-panel" id="shared-helpers"><h2>Shared Helpers</h2>',
    1,
)

page = page.replace(
    'placeholder="Search types, modules, globals..."',
    'placeholder="Search documentation..."',
    1,
)

index.write_text(page, encoding="utf-8")
print("Customized output/index.html")