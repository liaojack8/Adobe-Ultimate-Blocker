# Adobe Ultimate Blocker

一個整合並增強的自動化工具，旨在全面封鎖所有 Adobe 體系軟體（包括 Acrobat 與 Creative Cloud 等）的更新與遙測。

## 🌟 專案特色

* **雙重阻擋名單來源**：整合了針對 Adobe 的精準阻擋清單與大規模遙測阻擋清單，全面防堵任何「漏網之魚」。
* **強制防火牆規則**：自動掃描系統中的所有 Adobe 執行檔 (`.exe`)，並建立雙向 Windows 防火牆阻擋規則。
* **深層清理背景服務**：不僅移除常見的 Creative Cloud 更新服務 (`AGSService`, `AAMUpdater`)，更針對性地刪除了常被忽略的 Acrobat 專屬更新服務 (`AdobeARMservice`)。
* **一鍵執行**：附帶 Batch 腳本自動獲取系統管理員權限，無需繁瑣設定。

## 🛠️ 使用方法

1. 將本專案下載或 clone 到你的電腦中。
2. 找到並雙擊執行 `Run-Ultimate-Blocker.bat`。
3. 若系統彈出「使用者帳戶控制 (UAC)」視窗，請點選「是」允許執行。
4. 等待腳本執行完畢，所有更新與遙測即被成功封鎖。

## 🙏 致謝 (Acknowledgments)

本專案的誕生要感謝以下開源專案與作者的無私貢獻與靈感啟發：

* 特別感謝 [ignaciocastro/a-dove-is-dumb](https://github.com/ignaciocastro/a-dove-is-dumb) 提供龐大且持續更新的 Hosts 阻擋清單。
* 感謝 [Ruddernation-Designs/Adobe-URL-Block-List](https://github.com/Ruddernation-Designs/Adobe-URL-Block-List) 針對 Adobe 體系精心維護的精準 hosts 名單。
* 感謝 [ethanaicode/Adobe-Block-Hosts-List](https://github.com/ethanaicode/Adobe-Block-Hosts-List) 提供近期活躍更新的驗證伺服器阻擋名單。

## 🤖 自動化更新備份

本專案包含 GitHub Actions 工作流程，每天會定時檢查 `a.dove.isdumb.one` 的清單是否有更新，並自動同步備份一份名為 `list.txt` 的檔案至本專案中。當網路連線失敗時，腳本會自動退回使用此本地備份。
