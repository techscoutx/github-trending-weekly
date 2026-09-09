#!/bin/bash
# GitHub Trending report generator
# Usage: gen-report.sh <since> (daily|weekly|monthly)

set -e

SINCE="${1:-daily}"
DATE=$(date +%Y-%m-%d)
OPENCLI="/root/opencli/dist/src/main.js"
REPO_DIR="/root/github-trending-weekly"

case "$SINCE" in
  daily)   LABEL="日榜"; FILE_PREFIX="daily" ;;
  weekly)  LABEL="周榜"; FILE_PREFIX="weekly" ;;
  monthly) LABEL="月榜"; FILE_PREFIX="monthly" ;;
esac

OUTFILE="$REPO_DIR/reports/${FILE_PREFIX}-${DATE}.html"

# Fetch trending data
DATA=$($OPENCLI github-trending repos --limit 25 --since "$SINCE" -f json)

# Generate HTML via node
node -e "
const data = JSON.parse(process.argv[1]);
const date = '$DATE';
const label = '$LABEL';

const langColors = {
  Python:'#3572A5', JavaScript:'#f1e05a', TypeScript:'#3178c6',
  HTML:'#e34c26', Shell:'#89e051', Rust:'#dea584', Go:'#00ADD8',
  Java:'#b07219', 'C++':'#f34b7d', C:'#555555', Ruby:'#701516',
  Kotlin:'#A97BFF', Swift:'#F05138', Dart:'#00B4AB', Lua:'#000080',
  PHP:'#4F5D95', 'C#':'#178600', Zig:'#ec915c', Scala:'#c22d40',
  Vue:'#41b883', Svelte:'#ff3e00', Jupyter:'#F37626'
};

function fmtStars(n) {
  if (n >= 1000) return (n/1000).toFixed(1).replace(/\\.0$/,'') + 'k';
  return String(n);
}

const rows = data.map((p, i) => {
  const rank = i + 1;
  const color = langColors[p.language] || '#8b949e';
  const langHtml = p.language
    ? '<span class=\"lang-dot\" style=\"background:'+color+'\"></span>'+p.language
    : '';
  const topClass = rank <= 3 ? ' rank-top' : '';
  return '<div class=\"project\" onclick=\"this.classList.toggle(\\'open\\')\">'+
    '<div class=\"project-summary\">'+
      '<span class=\"rank'+topClass+'\">#'+rank+'</span>'+
      '<span class=\"name\"><a href=\"'+p.url+'\" target=\"_blank\" onclick=\"event.stopPropagation()\">'+p.repo+'</a></span>'+
      '<span class=\"oneliner\">'+(p.description||'')+'</span>'+
      '<span class=\"meta\">'+
        (langHtml ? '<span>'+langHtml+'</span>' : '')+
        '<span>⭐ '+fmtStars(p.stars)+'</span>'+
        '<span>+'+p.starsSince.toLocaleString()+'</span>'+
      '</span>'+
      '<span class=\"toggle-icon\">▶</span>'+
    '</div>'+
  '</div>';
}).join('\\n');

const html = \`<!DOCTYPE html>
<html lang=\"zh-CN\">
<head>
<meta charset=\"UTF-8\">
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
<title>GitHub \${label} \${date}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Helvetica,Arial,sans-serif;background:#0d1117;color:#c9d1d9;line-height:1.6;padding:40px 20px}
.container{max-width:1000px;margin:0 auto}
h1{color:#58a6ff;border-bottom:2px solid #21262d;padding-bottom:16px;margin-bottom:12px;font-size:1.8em}
.subtitle{color:#8b949e;margin-bottom:36px;font-size:.95em}
.project{background:#161b22;border:1px solid #30363d;border-radius:10px;margin-bottom:12px;transition:border-color .2s}
.project:hover{border-color:#58a6ff}
.project-summary{display:flex;align-items:center;padding:16px 20px;cursor:pointer;user-select:none;gap:16px}
.project-summary:hover{background:#1c2129;border-radius:10px}
.rank{font-size:1.1em;font-weight:bold;color:#8b949e;min-width:28px}
.rank-top{color:#f0883e}
.name{font-weight:600;color:#58a6ff;min-width:240px}
.name a{color:#58a6ff;text-decoration:none}
.name a:hover{text-decoration:underline}
.oneliner{flex:1;color:#c9d1d9;font-size:.92em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.meta{display:flex;gap:14px;color:#8b949e;font-size:.85em;flex-shrink:0}
.lang-dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:4px;vertical-align:middle}
.toggle-icon{color:#484f58;font-size:.8em;transition:transform .2s;flex-shrink:0}
.project.open .toggle-icon{transform:rotate(90deg)}
.footer{margin-top:48px;padding-top:20px;border-top:1px solid #21262d;color:#484f58;font-size:.85em;text-align:center}
.footer a{color:#58a6ff;text-decoration:none}
</style>
</head>
<body>
<div class=\"container\">
<h1>🔥 GitHub Trending \${label}</h1>
<p class=\"subtitle\">\${date} · Top 25</p>
\${rows}
<div class=\"footer\"><p>由 <a href=\"https://github.com/techscoutx\" target=\"_blank\">@techscoutx</a> 生成 · 数据来源 GitHub Trending</p></div>
</div>
</body>
</html>\`;

process.stdout.write(html);
" "$DATA" > "$OUTFILE"

# Git commit and push
cd "$REPO_DIR"

# Update index.html to point to latest
cat > index.html << EOF2
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta http-equiv="refresh" content="0;url=reports/${FILE_PREFIX}-${DATE}.html"><title>GitHub Trending Weekly</title></head>
<body><p>Redirecting to <a href="reports/${FILE_PREFIX}-${DATE}.html">latest report</a>...</p></body>
</html>
EOF2

git add -A
git commit -m "📊 ${LABEL} ${DATE}" --allow-empty
git push

echo "REPORT_URL=https://techscoutx.github.io/github-trending-weekly/reports/${FILE_PREFIX}-${DATE}.html"
