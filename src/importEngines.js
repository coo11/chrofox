// Given that making HTTP request on Chrome settings page is not allowed, you should paste your engine data here.
const engines = [];
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
