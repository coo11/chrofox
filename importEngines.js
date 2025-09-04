// 2025-09-04 04:14:39 UTC+0
// Given that making HTTP request on Chrome settings page is not allowed, you should paste your engine data here.
const engines = [{"name":"Bing","keyword":"bing","url":"https://www.bing.com/search?q=%s"},{"name":"Startpage","keyword":"sp","url":"https://www.startpage.com/sp/search?qadf=none&cat=web&pl=opensearch&language=english&query=%s"},{"name":"知乎","keyword":"zh","url":"https://www.zhihu.com/search?type=content&q=%s"},{"name":"淘宝","keyword":"tb","url":"https://s.taobao.com/search?q=%s"},{"name":"微博","keyword":"wb","url":"https://s.weibo.com/weibo/%s?Refer=index"},{"name":"哔哩哔哩","keyword":"b","url":"https://www.bilibili.com/search?keyword=%s"},{"name":"Twitter","keyword":"t","url":"https://x.com/search?q=%s"},{"name":"Youtube","keyword":"y","url":"https://www.youtube.com/results?search_query=%s&page={startPage?}&utm_source=opensearch"},{"name":"维基百科","keyword":"wk","url":"https://zh.wikipedia.org/w/index.php?search=%s"},{"name":"Steam","keyword":"st","url":"https://store.steampowered.com/search/?term=%s"},{"name":"GitHub","keyword":"gh","url":"https://github.com/search?q=%s"},{"name":"Github Gist","keyword":"gg","url":"https://gist.github.com/search?q=%s&ref=opensearch"},{"name":"Apple Music","keyword":"am","url":"https://music.apple.com/jp/search?term=%s"},{"name":"SoulPlus","keyword":"hj","url":"https://bbs.imoutolove.me/search.php?step=2&method=AND&sch_area=0&f_fid=all&sch_time=all&orderway=postdate&asc=DESC&keyword=%s"},{"name":"E-hentai","keyword":"eh","url":"https://e-hentai.org/?f_cats=0&advsearch=1&f_sname=on&f_stags=on&f_sfl=on&f_sfu=on&f_sft=on&f_search=%s"},{"name":"Exhentai","keyword":"ex","url":"https://exhentai.org/?f_cats=0&advsearch=1&f_sname=on&f_stags=on&f_sfl=on&f_sfu=on&f_sft=on&f_search=%s"},{"name":"紳士の庭","keyword":"gm","url":"https://gmgard.com/Blog/List?Query=%s"},{"name":"绅士仓库","keyword":"ck","url":"https://cangku.moe/search/post?q=%s"},{"name":"萌娘百科","keyword":"moe","url":"https://zh.moegirl.org.cn/index.php?search=%s"},{"name":"番组计划","keyword":"bgm","url":"https://bgm.tv/subject_search/%s?cat=all"},{"name":"Reddit","keyword":"re","url":"https://www.reddit.com/search/?q=%s"},{"name":"MDN Web","keyword":"mdn","url":"https://developer.mozilla.org/zh-CN/search?q=%s"},{"name":"Stack Overflow","keyword":"so","url":"https://stackoverflow.com/search?q=%s"},{"name":"小红书","keyword":"xhs","url":"https://www.xiaohongshu.com/search_result?keyword=%s"},{"name":"DuckDuckGo","keyword":"ddg","url":"https://duckduckgo.com/?q=%s&atb=v307-2__"},{"name":"天使动漫","keyword":"tsdm","url":"https://www.tsdm39.com/plugin.php?id=Kahrpba:search&authorid=0&fid=0&query=%s"},{"name":"LOFTER","keyword":"lo","url":"https://www.lofter.com/front/homesite/search?type=blog&q=%s"},{"name":"米画师","keyword":"mhs","url":"https://www.mihuashi.com/search?q=%s"},{"name":"百鸽卡查","keyword":"kc","url":"https://ygocdb.com/?search=%s"},{"name":"Google 翻译","keyword":"gtc","url":"https://translate.google.com/?sl=auto&tl=zh-CN&text=%s"},{"name":"Google Translate","keyword":"gte","url":"https://translate.google.com/?sl=auto&tl=en&text=%s"},{"name":"Google 翻訳","keyword":"gtj","url":"https://translate.google.com/?sl=auto&tl=ja&text=%s"},{"name":"百度翻译","keyword":"tc","url":"https://fanyi.baidu.com/translate?lang=auto2zh&query=%s"},{"name":"Baidu Translate","keyword":"te","url":"https://fanyi.baidu.com/translate?lang=auto2en&query=%s"},{"name":"百度翻訳","keyword":"tj","url":"https://fanyi.baidu.com/translate?lang=auto2jp&query=%s"}];
const querySelectorS = (selector, root) => {
  const parts = selector.split(/\s*>>>\s*/);
  let currentRoot = root ? root.shadowRoot : document;
  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    const el = currentRoot.querySelector(part);
    if (!el) return null;
    if (i < parts.length - 1) {
      if (el.shadowRoot) {
        currentRoot = el.shadowRoot;
      } else return null;
    } else return el;
  }
  return null;
};
const wait = (ms = 100) => new Promise(resolve => setTimeout(resolve, ms));
const searchEngineChanger = {
  init() {
    this.searchEnginePage = querySelectorS("settings-ui>>>#main>>>settings-basic-page>>>settings-search-page>>>settings-search-engines-page");
    this.addButton = querySelectorS("#addSearchEngine", this.searchEnginePage);
  },
  async clearAllEngines(inactiveOnly = false, deactiveBuiltIn = true) {
    const searchEngineLists = this.searchEnginePage.shadowRoot.querySelectorAll("settings-search-engines-list");
    const removeOrDeactiveEntries = async (section, isInactiveSection = false, nextEntry = 0) => {
      let selector = "settings-search-engine-entry";
      if (nextEntry) selector += `:nth-child(${nextEntry})`;
      const entry = section.querySelector(selector);
      if (!entry) return;
      const deleteButton = entry.shadowRoot.querySelector("button#delete");
      if (deleteButton && !deleteButton.hidden) {
        deleteButton.click();
        await wait();
        return await removeOrDeactiveEntries(section, isInactiveSection);
      }
      if (!isInactiveSection && deactiveBuiltIn) {
        const deactiveButton = entry.shadowRoot.querySelector("button#deactivate");
        if (deactiveButton && !deactiveButton.hidden) {
          deactiveButton.click();
          await wait();
          return await removeOrDeactiveEntries(section);
        }
      }
      return await removeOrDeactiveEntries(section, isInactiveSection, ++nextEntry);
    };
    if (!inactiveOnly) await removeOrDeactiveEntries(searchEngineLists[1].shadowRoot);
    await removeOrDeactiveEntries(searchEngineLists[2].shadowRoot, true);
    return;
  },
  async addNewEngine({ name, keyword, url }) {
    this.addButton.click();
    await wait();
    const dialog = this.searchEnginePage.shadowRoot.querySelector("settings-search-engine-edit-dialog");
    const nameInput = querySelectorS("#searchEngine>>>#input", dialog);
    const keywordInput = querySelectorS("#keyword>>>#input", dialog);
    const urlInput = querySelectorS("#queryUrl>>>#input", dialog);
    const addButton = dialog.shadowRoot.querySelector("#actionButton");
    nameInput.value = name;
    keywordInput.value = keyword;
    urlInput.value = url;
    nameInput.dispatchEvent(new InputEvent("input"));
    keywordInput.dispatchEvent(new InputEvent("input"));
    urlInput.dispatchEvent(new InputEvent("input"));
    while (addButton.disabled) {
      console.log(
        "%cPlease click any input box except the first one to focus it. The script will continue automatically once the button is enabled…",
        "color:orange;font-size:16px;"
      );
      await wait(200);
    }
    addButton.click();
    await wait();
  },
  async importEngines() {
    for (const engine of engines) {
      const failedImport = await this.addNewEngine(engine);
      if (failedImport) console.warn("Failed to import " + JSON.stringify(failedImport));
    }
  }
};
searchEngineChanger.init();
await searchEngineChanger.clearAllEngines();
searchEngineChanger.importEngines();
