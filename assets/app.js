// 渲染器 + 搜索 + KaTeX 触发
(function () {
  const SECTION_TITLE = {
    "题目": "题目",
    "知识点": "知识点",
    "推导": "推导",
    "代码": "完整代码",
    "提示": "提示",
    "易错点": "易错点"
  };

  function esc(s) {
    return String(s).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  function renderKnowledge(items) {
    if (!items || !items.length) return "";
    return (
      '<div class="know-box"><h3>核心知识点</h3><ul>' +
      items.map(it => "<li>" + it + "</li>").join("") +
      "</ul></div>"
    );
  }

  function renderFormulas(items) {
    if (!items || !items.length) return "";
    return items.map(f => (
      '<div class="formula-box"><div class="ftitle">' + f.title + "</div>" + f.body + "</div>"
    )).join("");
  }

  function renderSection(sec) {
    const t = sec.type;
    if (t === "代码") {
      return '<h5>完整代码</h5><pre class="code">' + sec.code + "</pre>";
    }
    if (t === "提示") {
      return '<div class="tip">' + sec.html + "</div>";
    }
    if (t === "易错点") {
      return '<div class="warn">' + sec.html + "</div>";
    }
    const title = SECTION_TITLE[t] || t;
    return "<h5>" + title + "</h5>" + sec.html;
  }

  function renderProblem(p) {
    const body = (p.sections || []).map(renderSection).join("");
    return (
      '<div class="problem">' +
      '<div class="prob-header"><span class="arrow">&#9654;</span><h4>' + p.title + "</h4></div>" +
      '<div class="prob-body">' + body + "</div>" +
      "</div>"
    );
  }

  function renderChapter(ch) {
    const header =
      '<div class="chapter-header">' +
      '<span class="arrow">&#9654;</span>' +
      "<h2>" + ch.title + "</h2>" +
      '<span class="tag">' + ch.tag + "</span>" +
      "</div>";
    const body =
      '<div class="chapter-body">' +
      renderKnowledge(ch.knowledge) +
      renderFormulas(ch.formulas) +
      (ch.problems || []).map(renderProblem).join("") +
      "</div>";
    return '<div class="chapter" id="' + ch.id + '">' + header + body + "</div>";
  }

  function renderToc(manifest) {
    const ul = document.querySelector(".toc ul");
    if (!ul) return;
    ul.innerHTML = manifest.map(m => (
      '<li><a href="#' + m.id + '">' + m.nav + "</a></li>"
    )).join("");
  }

  async function loadAll() {
    const content = document.getElementById("content");
    try {
      const manifestResp = await fetch("data/manifest.json");
      if (!manifestResp.ok) throw new Error("manifest.json 加载失败 (" + manifestResp.status + ")");
      const manifest = await manifestResp.json();
      renderToc(manifest);

      const chapters = await Promise.all(
        manifest.map(m => fetch("data/" + m.file).then(r => {
          if (!r.ok) throw new Error(m.file + " 加载失败");
          return r.json();
        }))
      );

      content.innerHTML = chapters.map(renderChapter).join("");

      if (window.renderMathInElement) {
        window.renderMathInElement(content, {
          delimiters: [
            { left: "$$", right: "$$", display: true },
            { left: "$", right: "$", display: false }
          ],
          ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"],
          throwOnError: false
        });
      }

      bindInteractions();
    } catch (err) {
      content.innerHTML =
        '<div class="error"><b>加载失败：</b>' + err.message +
        '<br>常见原因：未通过 HTTP 服务器打开本页（直接双击 <code>index.html</code> 会触发浏览器 file:// 限制）。' +
        '请使用 VS Code 的 Live Server 插件启动，详见 README。</div>';
    }
  }

  function bindInteractions() {
    document.addEventListener("click", function (e) {
      const ch = e.target.closest(".chapter-header");
      if (ch) {
        ch.classList.toggle("open");
        ch.nextElementSibling.classList.toggle("open");
      }
      const pr = e.target.closest(".prob-header");
      if (pr) {
        pr.classList.toggle("open");
        pr.nextElementSibling.classList.toggle("open");
      }
    });
    window.addEventListener("beforeprint", () => {
      document.querySelectorAll(".chapter-header,.prob-header").forEach(h => h.classList.add("open"));
      document.querySelectorAll(".chapter-body,.prob-body").forEach(b => b.classList.add("open"));
    });
    initSearch();
  }

  // ====== 搜索功能 ======
  function initSearch() {
    const box = document.getElementById("searchBox");
    const clr = document.getElementById("searchClear");
    const cnt = document.getElementById("searchCount");
    if (!box) return;

    // 跳过 KaTeX 渲染后的节点，避免破坏公式结构
    function isKatexNode(node) {
      if (!node || node.nodeType !== 1) return false;
      const cls = node.className;
      if (typeof cls !== "string") return false;
      return cls.indexOf("katex") !== -1;
    }

    function clearHighlights(root) {
      root.querySelectorAll("span.hit").forEach(s => {
        const p = s.parentNode;
        p.replaceChild(document.createTextNode(s.textContent), s);
        p.normalize();
      });
    }

    function highlight(node, re) {
      if (isKatexNode(node)) return;
      if (node.nodeType === 3) {
        const txt = node.nodeValue;
        if (!re.test(txt)) return;
        re.lastIndex = 0;
        const frag = document.createDocumentFragment();
        let last = 0, m;
        while ((m = re.exec(txt)) !== null) {
          if (m.index > last) frag.appendChild(document.createTextNode(txt.slice(last, m.index)));
          const sp = document.createElement("span"); sp.className = "hit"; sp.textContent = m[0];
          frag.appendChild(sp);
          last = m.index + m[0].length;
          if (m.index === re.lastIndex) re.lastIndex++;
        }
        if (last < txt.length) frag.appendChild(document.createTextNode(txt.slice(last)));
        node.parentNode.replaceChild(frag, node);
      } else if (node.nodeType === 1 && !["SCRIPT", "STYLE"].includes(node.tagName)) {
        Array.from(node.childNodes).forEach(c => highlight(c, re));
      }
    }

    function run() {
      const q = box.value.trim();
      const content = document.getElementById("content");
      clearHighlights(content);
      const chapters = content.querySelectorAll(".chapter");
      const probs = content.querySelectorAll(".problem");

      if (!q) {
        clr.classList.remove("active");
        cnt.textContent = "";
        chapters.forEach(c => c.classList.remove("hidden"));
        probs.forEach(p => p.classList.remove("hidden"));
        content.querySelectorAll(".chapter-header,.prob-header").forEach(h => h.classList.remove("open"));
        content.querySelectorAll(".chapter-body,.prob-body").forEach(b => b.classList.remove("open"));
        return;
      }
      clr.classList.add("active");
      const ql = q.toLowerCase();
      let hitCount = 0;

      probs.forEach(p => {
        const txt = p.textContent.toLowerCase();
        if (txt.includes(ql)) {
          p.classList.remove("hidden");
          const ph = p.querySelector(".prob-header");
          const pb = p.querySelector(".prob-body");
          if (ph) ph.classList.add("open");
          if (pb) pb.classList.add("open");
          hitCount++;
        } else {
          p.classList.add("hidden");
        }
      });

      chapters.forEach(c => {
        const visibleProb = c.querySelector(".problem:not(.hidden)");
        const knowMatch = Array.from(c.querySelectorAll(".know-box, .formula-box, .chapter-header"))
          .some(b => b.textContent.toLowerCase().includes(ql));
        if (visibleProb || knowMatch) {
          c.classList.remove("hidden");
          const ch = c.querySelector(".chapter-header");
          const cb = c.querySelector(".chapter-body");
          if (ch) ch.classList.add("open");
          if (cb) cb.classList.add("open");
        } else {
          c.classList.add("hidden");
        }
      });

      cnt.textContent = hitCount + " 命中";

      try {
        const re = new RegExp(esc(q), "gi");
        content.querySelectorAll(
          ".chapter:not(.hidden) .chapter-header h2, " +
          ".problem:not(.hidden) .prob-header h4, " +
          ".problem:not(.hidden) .prob-body, " +
          ".chapter:not(.hidden) .know-box, " +
          ".chapter:not(.hidden) .formula-box"
        ).forEach(el => highlight(el, re));
      } catch (e) { /* ignore */ }
    }

    let timer;
    box.addEventListener("input", () => { clearTimeout(timer); timer = setTimeout(run, 150); });
    clr.addEventListener("click", () => { box.value = ""; run(); box.focus(); });
    box.addEventListener("keydown", e => { if (e.key === "Escape") { box.value = ""; run(); } });
  }

  document.addEventListener("DOMContentLoaded", loadAll);
})();
