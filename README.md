# 全球匯率通 Global FX Tracker (Flutter Android 專案)

本專案參考網頁匯率介面設計（`public/assets/aistudio/SCR-20261113-dxvh_fcb70b4c.png`）與原生圖表邏輯，使用 **Flutter** 完整改寫，支援即時匯率連線、1D–10Y 互動走勢圖、三幣疊加對比、JPG 高解析匯出分享，以及多達 10 種貨幣的互動即時速算表。

## 主要功能

1. **即時匯率 API 雙重備援與盤中連線**
   - **主即時現貨 API**：`https://open.er-api.com/v6/latest/USD`（支援 160+ 貨幣，含 TWD、VND、AED、HKD、JPY 等）
   - **備援現貨 & 歷史日線 API**：`https://api.frankfurter.dev/v1/latest` 與 `https://api.frankfurter.dev/v1/{start}..{end}`（歐洲央行 ECB 數據）
   - **1D 分時盤中 API**：`https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1h&range=2d`
   - **離線基準帳本備援**：內建 `assets/rates_2016_2026.json`（2016–2026 年歷史基準匯率）與 `HourlyRateLedger`，即使斷網也能立即顯示完整曲線與換算。
   - Android `AndroidManifest.xml` 已設定 `android.permission.INTERNET` 與 `android.permission.ACCESS_NETWORK_STATE`。

2. **三大核心頁面**
   - **走勢圖 (Pair Chart)**：From / Swap / To 貨幣選擇器、漲跌幅標籤、`1 BASE = X TARGET` 即時報價、`1D / 1W / 1M / 1Y / 5Y / 10Y` 分段切換、三次貝茲平滑曲線 + 漸層填充 + 右側 Y 軸刻度 + 觸控拖曳查價（Scrubber）、期間高/低/均價統計、1200×800 JPG 匯出與分享。
   - **三幣疊加 (3-FX Overlay)**：1 主幣同時對比 3 種貨幣，支援「百分比漲跌幅 (%)（含 0% 基準虛線）」與「各自匯率對比」雙模式切換、即時圖例與 1200×850 JPG 匯出。
   - **多幣速算表 (Converter Table)**：支援最多 10 種貨幣同步換算、點擊任意列切換為輸入貨幣、`+100 / +1000 / +10000` 快加、一鍵複製金額與增刪貨幣。

3. **多語言與主題**
   - 支援 **繁體中文**、**简体中文**、**English** 即時切換。
   - 支援 **跟隨系統 / 淺色 / 深色** 主題模式與偏好持久化。

## 編譯 Android APK 指令

請在已安裝 **Flutter SDK**、**JDK 17** 與 **Android SDK** 的環境中執行：

```bash
cd flutter_fx_tracker
flutter pub get
flutter test
flutter build apk --release
```

編譯完成後的 APK 路徑位於：
`flutter_fx_tracker/build/app/outputs/flutter-apk/app-release.apk`
