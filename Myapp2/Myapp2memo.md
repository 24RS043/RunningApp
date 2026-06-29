# MyApp2 開発メモ

ランニング × RPG のiOSアプリ。走った距離でゲームが進行し、ミッションでポイントを貯めてバトルに挑む。

---

## 目次

1. [アプリの全体像](#アプリの全体像)
2. [使用している技術](#使用している技術)
3. [データの流れ](#データの流れ)
4. [ファイル一覧と役割](#ファイル一覧と役割)
5. [各ファイルの詳細](#各ファイルの詳細)
6. [ゲームの仕組みまとめ](#ゲームの仕組みまとめ)

---

## アプリの全体像

このアプリは大きく「ランニング機能」と「ゲーム機能」の2つで構成されている。

- **ランニング機能**：GPSで走行を計測し、距離・時間・カロリー・ルートを記録。履歴と統計を表示する。
- **ゲーム機能**：走った距離でワールドマップが進み、ミッションでポイントを貯め、ステージでターン制バトルを行いキャラを育成する。

走る → ミッション達成でポイント獲得 → ポイントを使ってバトル → 勝つと経験値でレベルアップ、というループが中心。

### 画面（タブ）構成

| タブ | 画面 | 役割 |
|------|------|------|
| ホーム | HomeView | 走行統計の表示、ログイン/距離ミッションの判定 |
| 計測 | RunView | ランニングの開始・停止、リアルタイム表示 |
| 履歴 | HistoryView | 過去の走行記録の一覧・削除 |
| 冒険 | GameView | キャラ画面とマップ画面をセグメントで切替 |
| 設定 | ProfileView | 表示名・体重の設定、ログアウト |

---

## 使用している技術

| 技術 | 用途 |
|------|------|
| SwiftUI | 画面（UI）の構築 |
| Firebase Authentication | ログイン・新規登録（メール＋パスワード） |
| Firebase Firestore | ランニング記録・プロフィールのクラウド保存 |
| SwiftData | ゲームデータ（キャラ・進行状況）の端末内保存 |
| CoreLocation | GPSによる位置・距離の取得 |
| MapKit | 地図表示・ルート描画 |
| Combine | データ変更の画面への自動反映（ObservableObject） |

### 保存先の使い分け

- **Firestore（クラウド）**：ランニング記録、プロフィール → 複数端末で共有でき、ログインユーザーごとに分かれる
- **SwiftData（端末内）**：キャラのステータス、ゲーム進行状況 → その端末だけのローカルデータ

---

## データの流れ

### 起動〜ログイン
```
MyApp2App（アプリの入口）
  └ AuthManager がログイン状態を監視
      ├ 未ログイン → LoginView
      └ ログイン済み → ContentView（タブ画面本体）
```

### ContentView が各係（Store）を配る
```
ContentView
  ├ RunRecordStore   … ランニング記録の係（Firestore）
  ├ UserProfileStore … プロフィールの係（Firestore）
  └ LocationManager  … GPS計測の係
      └ 計測終了時、RunRecordStore に保存を依頼
```

### ゲームデータの流れ
```
SwiftData
  ├ GameCharacter … キャラのステータス（1体）
  └ GameProgress  … 進行状況（到達距離・ミッション受取記録）

各画面が @Query で読み出し、MissionManager 経由でポイントを増減する
```

---

## ファイル一覧と役割

### モデル（データの形を定義）

| ファイル | 役割 |
|---------|------|
| RunRecord.swift | 1回分のランニング記録の構造体 |
| GameCharacter.swift | ゲームキャラのステータス（SwiftData） |
| GameProgress.swift | ゲーム進行状況（SwiftData） |
| Enemy.swift | 敵キャラのデータ |
| Stage.swift | ワールドマップのステージ定義 |

### 係（ロジック・データ管理）

| ファイル | 役割 |
|---------|------|
| AuthManager.swift | ログイン・新規登録・ログアウト |
| RunRecordStore.swift | ランニング記録のFirestore保存・読込・削除＋統計計算 |
| UserProfileStore.swift | プロフィールのFirestore保存・読込 |
| LocationManager.swift | GPS計測、距離・ラップ・カロリー計算 |
| BattleManager.swift | バトルの進行ロジック（ターン制） |
| MissionManager.swift | ミッション判定とポイント付与 |

### 画面（View）

| ファイル | 役割 |
|---------|------|
| MyApp2App.swift | アプリの入口、ログイン状態で画面切替 |
| ContentView.swift | タブ画面の本体、各係を配る |
| LoginView.swift | ログイン・新規登録画面 |
| HomeView.swift | ホーム（統計＋ミッション） |
| RunView.swift | ランニング計測画面 |
| HistoryView.swift | 走行履歴一覧 |
| RouteDetailView.swift | 1記録の詳細（ルート地図＋ラップ） |
| ProfileView.swift | 設定画面 |
| GameView.swift | 冒険タブ（キャラ⇄マップの切替） |
| CharacterView.swift | キャラステータス画面 |
| WorldMapView.swift | ワールドマップ画面 |
| BattleView.swift | バトル画面 |

---

## 各ファイルの詳細

---

### RunRecord.swift（モデル）

1回分のランニング記録を表す構造体。`Codable` でJSON変換でき、`Identifiable` でリスト表示できる。

| 変数 | 型 | 役割 |
|------|-----|------|
| id | String | 記録を識別するID（FirestoreのドキュメントID） |
| date | Date | ランニングを終えた日時 |
| distance | Double | 走行距離（m） |
| time | Int | 走行時間（秒） |
| calories | Double | 消費カロリー |
| route | [RoutePoint] | 走行ルート（緯度経度の配列） |
| laps | [Int] | 1kmごとの区間タイム（秒）の配列 |

**RoutePoint**：ルート上の1点を表す。`latitude`（緯度）と `longitude`（経度）を持つ。

---

### GameCharacter.swift（モデル・SwiftData）

ゲームのプレイヤーキャラ。`@Model` を付けることでSwiftDataが端末内に保存してくれる。基本的に1体だけ存在する。

| 変数 | 型 | 役割 |
|------|-----|------|
| name | String | キャラ名（初期値"勇者"。表示はプロフィール名を使用） |
| level | Int | レベル |
| exp | Int | 現在の経験値 |
| maxHP | Int | 最大HP |
| attack | Int | 攻撃力 |
| defense | Int | 防御力 |
| points | Int | 所持ポイント |

| 計算プロパティ | 役割 |
|--------------|------|
| expToNextLevel | 次のレベルに必要な経験値（`level × 100`） |

---

### GameProgress.swift（モデル・SwiftData）

ゲームの進行状況とミッションの受取記録を保存する。`@Model` で端末内に保存。基本的に1つだけ存在する。

| 変数 | 型 | 役割 |
|------|-----|------|
| maxReachedDistance | Double | これまで到達した累計距離の最大値（m）。一度増えたら減らない。履歴を削除してもマップ解放が戻らないようにするための値 |
| lastLoginBonusDate | Date? | 最後にログインボーナスを受け取った日 |
| lastRunBonusDate | Date? | 最後にランニング達成ボーナスを受け取った日 |
| rewardedDistance | Double | すでにポイントに換算済みの距離（m）。3kmごとのポイントを二重に配らないための記録 |

---

### Enemy.swift（モデル）

敵キャラのデータ。`EnemyData` に具体的な敵が定義されている。

| 変数 | 型 | 役割 |
|------|-----|------|
| id | UUID | 識別用ID |
| name | String | 敵の名前 |
| hp | Int | 現在HP（戦闘中に減る） |
| maxHP | Int | 最大HP |
| attack | Int | 攻撃力 |
| defense | Int | 防御力 |
| expReward | Int | 倒したときに得る経験値 |

**EnemyData**（定義済みの敵）：
- `slime` … スライム（弱）※現在は未使用
- `goblin` … ゴブリン（雑魚戦で出現）
- `boss` … ドラゴン（ボス戦で出現）

---

### Stage.swift（モデル）

ワールドマップのステージを定義する。

**StageType（ステージの種類・enum）**

| ケース | 意味 |
|-------|------|
| battle | 戦闘（雑魚敵） |
| shop | ショップ（現在は未使用） |
| boss | ボス |

| StageTypeのプロパティ | 役割 |
|---------------------|------|
| iconName | ステージのアイコン名（SF Symbols） |
| label | 表示名（"戦闘""ボス"など） |
| requiredPoints | 挑戦に必要なポイント（戦闘1・ボス2・ショップ0） |

**Stage（1つのステージ）**

| 変数 | 型 | 役割 |
|------|-----|------|
| id | Int | 何番目のステージか（0始まり） |
| type | StageType | ステージの種類 |
| requiredDistance | Double | 解放に必要な累計距離（m） |

| 関数 | 役割 |
|------|------|
| isUnlocked(totalDistance:) | 渡された距離で解放済みか判定 |

**StageData.all**：全ステージの一覧。現在は8ステージ（戦闘7＋ボス1）で、1kmごとに1ステージ解放される設定。

---

### AuthManager.swift（係）

Firebase Authenticationを使ってログイン状態を管理する。`ObservableObject` なので状態変化が画面に自動反映される。

| 変数 | 型 | 役割 |
|------|-----|------|
| isLoggedIn | Bool | ログインしているか |
| userId | String? | ログイン中のユーザーID |

| 関数 | 役割 |
|------|------|
| init() | 起動時にログイン状態を反映し、変化を監視する |
| signUp(email:password:completion:) | 新規登録。失敗時はエラー文を返す |
| login(email:password:completion:) | ログイン。失敗時はエラー文を返す |
| logout() | ログアウト |

---

### RunRecordStore.swift（係）

ランニング記録をFirestoreで管理する。記録の保存・読込・削除に加え、統計値を計算する。

| 変数 | 型 | 役割 |
|------|-----|------|
| records | [RunRecord] | 履歴一覧（画面に表示される） |
| errorMessage | String? | エラー発生時のメッセージ（アラート表示用） |
| currentUserId | String? | ログイン中のユーザーID |

| 計算プロパティ | 役割 |
|--------------|------|
| totalDistance | 全記録の合計距離（m） |
| runCount | ラン回数 |
| totalTime | 累計時間（秒） |
| totalCalories | 累計カロリー |
| longestDistance | 最長距離（m） |
| averagePace | 平均ペース（秒/km） |

| 関数 | 役割 |
|------|------|
| add(_:) | 1件の記録をFirestoreに保存し、画面一覧の先頭に追加 |
| load() | 自分の記録をFirestoreから新しい順に読み込む |
| delete(at:) | スワイプ削除。Firestoreと画面の両方から消す。失敗時は再読込して復元 |

---

### UserProfileStore.swift（係）

プロフィール（表示名・体重）をFirestoreで管理する。

| 変数 | 型 | 役割 |
|------|-----|------|
| displayName | String | 表示名（ニックネーム） |
| weight | Double | 体重（kg。カロリー計算に使う） |
| currentUserId | String? | ログイン中のユーザーID |

| 関数 | 役割 |
|------|------|
| load() | 自分のプロフィールをFirestoreから読み込む |
| save() | 現在のプロフィールをFirestoreに保存（merge で既存を壊さない） |

---

### LocationManager.swift（係）

GPSを使ってランニングを計測する。距離・時間・ラップ・カロリーを計算し、終了時にRunRecordStoreへ保存を依頼する。

| 変数 | 型 | 役割 |
|------|-----|------|
| manager | CLLocationManager | iPhoneのGPS本体 |
| elapsedTime | Int | 経過時間（秒） |
| distance | Double | 走行距離（m） |
| calories | Double | 消費カロリー |
| timer | Timer? | 1秒ごとに時間を進めるタイマー |
| previousLocation | CLLocation? | 前回のGPS位置（距離計算に使う） |
| route | [CLLocationCoordinate2D] | 走行ルート（地図に描く） |
| laps | [Int] | 1kmごとの区間タイム |
| nextLapDistance | Double | 次にラップを刻む距離 |
| lastLapTime | Int | 前回ラップ時の経過時間 |
| profileStore | UserProfileStore? | 体重を取得するための係 |
| store | RunRecordStore? | 保存を依頼する係 |
| isRunning | Bool | 走行中か |
| lastRunQualified | Bool | 直近のランが1km以上だったか（ミッション判定用フラグ） |
| region | MKCoordinateRegion | 地図の表示範囲 |

| 関数 | 役割 |
|------|------|
| init() | GPSの許可を求め、更新を受け取る準備 |
| startRunning() | 計測開始。距離・時間・ラップをリセットしてタイマー開始 |
| stopRunning() | 計測終了。カロリー計算→記録を作成→保存依頼→1km以上ならフラグを立てる |
| locationManager(_:didUpdateLocations:) | GPS更新ごとに呼ばれる。精度の悪い点を除外し、距離を加算、ラップを刻み、地図を追従させる |

**ポイント**：GPS精度が20mより悪い点は捨ててブレを抑えている。距離が1km・2km…を超えるたびにラップを自動記録する。

---

### BattleManager.swift（係）

ターン制バトルの進行を管理する。`ObservableObject` で状態を画面に反映する。

| 変数 | 型 | 役割 |
|------|-----|------|
| enemy | Enemy | 戦う敵 |
| playerHP | Int | プレイヤーの現在HP |
| logs | [String] | 戦闘ログ |
| isPlayerTurn | Bool | プレイヤーのターンか |
| isFinished | Bool | 戦闘が終了したか |
| didWin | Bool | 勝ったか |
| playerSP | Int | 残りスキル使用回数 |
| character | GameCharacter | プレイヤーキャラ（ステータス参照用） |
| playerName | String | ログ表示用の名前（プロフィール名） |
| maxSP | Int | スキルの最大使用回数（3） |
| isDefending | Bool | 防御中か（次の敵攻撃を半減） |

| 関数 | 役割 |
|------|------|
| init(character:enemy:playerName:) | バトル開始。HP・SPを初期化 |
| attack() | 通常攻撃。`攻撃力 − 敵防御` のダメージ |
| defend() | 防御。次の敵の攻撃を半減 |
| skill() | スキル。SPを1消費して攻撃力1.5倍の攻撃 |
| checkEnemyDefeated() | 敵が倒れたか判定。倒したら勝利、まだなら敵ターンへ |
| endPlayerTurn() | プレイヤーのターンを終え、少し待って敵が攻撃 |
| enemyAttack() | 敵の攻撃。防御中なら半減。HPが0なら敗北 |

**攻撃とスキルの差別化**：攻撃はいつでも使えるが、スキルは強力なぶん1戦闘3回まで。SPを温存する駆け引きが生まれる。

---

### MissionManager.swift（係）

3つのミッションの判定とポイント付与をまとめる。すべて `static`（インスタンス不要）。

**ミッション内容**

| ミッション | 報酬 | 条件 |
|----------|------|------|
| ログインボーナス | +1pt | 1日1回アプリを開く |
| ランニング達成 | +2pt | 1日1回・1km以上走る |
| 距離達成 | +1pt | 累計3kmごと |

| 関数 | 役割 |
|------|------|
| checkAll(...) | 3つまとめて判定（※現在は未使用） |
| checkLoginBonus(...) | ログインボーナス判定・付与 |
| checkRunBonus(...) | ランニング達成判定・付与 |
| checkDistanceMilestone(...) | 距離達成判定・付与（3kmごとにまとめて精算） |
| isSameDay(_:_:) | 2つの日付が同じ日か判定 |
| loginBonusClaimed(...) | （表示用）今日もう受け取ったか |
| runBonusClaimed(...) | （表示用）今日もう受け取ったか |
| distanceToNextMilestone(...) | （表示用）次の距離達成まであと何m |

---

### MyApp2App.swift（画面・入口）

アプリの起動点。`@main` が付いている。

- `AppDelegate`：起動時にFirebaseを初期化する
- `authManager`：アプリ全体で1つだけ持つログインの係
- ログイン状態で画面を切り替える（未ログイン→LoginView、ログイン済み→ContentView）
- `.modelContainer(for:)` でSwiftDataの保存対象（GameCharacter・GameProgress）を登録

---

### ContentView.swift（画面・本体）

ログイン後のタブ画面本体。各係（Store）を生成し、各画面に配る。

| 変数 | 役割 |
|------|------|
| authManager | ログインの係（外から受け取る） |
| locationManager | GPS計測の係 |
| store | ランニング記録の係 |
| profileStore | プロフィールの係 |

`.onAppear` で、ログインユーザーIDを各係に伝え、`LocationManager` に保存先を渡し、履歴とプロフィールを読み込む。

---

### LoginView.swift（画面）

ログイン・新規登録の画面。1つの画面でモードを切り替える。

| 変数 | 役割 |
|------|------|
| email / password | 入力値 |
| errorMessage | エラー表示 |
| isSignUpMode | 新規登録モードか |

| 関数 | 役割 |
|------|------|
| handleMainAction() | ボタン押下時、モードに応じてログインor新規登録を実行 |

---

### HomeView.swift（画面）

ホーム画面。走行統計とミッション一覧を表示し、ログイン・距離ミッションを判定する。

主な表示：累計距離（大きなカード）、統計グリッド（ラン回数・累計時間・カロリー・最長距離）、平均ペース、ミッション一覧。

| 関数 | 役割 |
|------|------|
| statCard(...) | 統計カード1枚を作る |
| timeString(_:) | 秒を「1h 23m」形式に変換 |
| paceString(_:) | 秒/kmを「5'30"」形式に変換 |
| missionRow(...) | ミッション1行を作る |
| checkMissions() | ログイン＋距離ミッションを判定し、獲得したらアラート表示 |

---

### RunView.swift（画面）

ランニング計測画面。地図、時間・距離、Start/Stopボタン、平均ペースを表示する。

主な表示：現在地と走行ルートの地図、時間と距離、Start/Stopボタン、平均ペース。

| 関数 | 役割 |
|------|------|
| checkRunBonus() | 1km以上のランが終わったときにランニング達成ミッションを判定 |

**仕組み**：`LocationManager.lastRunQualified` のフラグ変化を `.onChange` で監視し、立ったらポイント判定する。

---

### HistoryView.swift（画面）

走行履歴の一覧。各記録をタップすると詳細（RouteDetailView）へ。スワイプで削除できる。エラー時はアラートを表示。

---

### RouteDetailView.swift（画面）

1つの記録の詳細。上半分に走行ルートの地図、下半分にラップ（1kmごとのタイム）一覧を表示する。

| 計算プロパティ | 役割 |
|--------------|------|
| coordinates | 記録のルートを地図用の座標に変換 |
| region | ルート全体が画面に収まる表示範囲を計算 |

---

### ProfileView.swift（画面）

設定画面。表示名と体重を入力・保存し、ログアウトもできる。

---

### GameView.swift（画面）

冒険タブの本体。上部のセグメントで「キャラ」と「マップ」を切り替える。`NavigationStack` をここで1つ持ち、中身（CharacterContent / WorldMapContent）にはNavigationStackを付けない。

| 変数 | 役割 |
|------|------|
| selectedTab | 表示中のページ（0=キャラ、1=マップ） |

---

### CharacterView.swift（画面）

キャラのステータス画面。

- **CharacterView**：旧バージョン（標準Form）。現在は未使用。
- **CharacterContent**：現在使われている版。カード＋アイコンのデザイン。冒険タブで表示される。

主な表示：アイコン付きのキャラ情報カード、EXPバー、ステータスグリッド（HP・攻撃・防御・ポイント）。名前はプロフィールの表示名を使う。

| 関数 | 役割 |
|------|------|
| statusView(_:) | ステータス全体の表示 |
| statBox(...) | ステータス1マスを作る |

---

### WorldMapView.swift（画面）

ワールドマップ画面（中身は `WorldMapContent`）。累計距離でステージが解放され、ポイントを消費してバトルに挑む。

| 変数 | 役割 |
|------|------|
| notEnoughPoints | ポイント不足アラートの表示フラグ |
| battleStage | 挑戦するステージ（セットされるとバトルへ遷移） |
| unlockDistance | 解放判定に使う距離（到達最大と現在合計の大きいほう） |

| 関数 | 役割 |
|------|------|
| tryStartBattle(_:) | ポイントを確認し、足りれば消費してバトル開始、足りなければ通知 |
| stageRow(_:) | ステージ1行の見た目を作る |
| updateProgress() | 到達した最大距離を更新（増えたときだけ保存） |
| color(for:) | ステージ種類ごとの色 |
| enemy(for:) | ステージに対応する敵を返す |

**仕組み**：紫ヘッダーに累計距離と所持ポイントを表示。解放済みの戦闘・ボスはタップでポイント判定→バトルへ。未解放は「あと○m」と表示。

---

### BattleView.swift（画面）

バトル画面。敵・戦闘ログ・プレイヤー・コマンドボタンを表示する。

主な表示：敵エリア（赤背景＋HPバー）、戦闘ログ（最新3件）、プレイヤーカード（HPバー＋SPを●で表示）、コマンドボタン（攻撃・防御・スキル）。

| 関数 | 役割 |
|------|------|
| init(character:enemy:playerName:) | バトルを初期化 |
| enemyHPBar() | 敵のHPバー |
| battleCommand(...) | コマンドボタン1つを作る |
| giveRewards() | 勝利時に経験値を加算し、必要ならレベルアップ処理 |

**レベルアップ**：経験値が必要量を超えると、レベル+1、HP+20、攻撃+3、防御+2される（条件を満たす限り繰り返す）。勝ってもポイントは増えない（ポイント入手はミッションのみ）。

---

## ゲームの仕組みまとめ

### ポイントの流れ

**入手（ミッション）**
- ログイン：1日1回 +1pt
- ランニング達成：1日1回・1km以上で +2pt
- 距離達成：累計3kmごと +1pt

**消費（バトル挑戦）**
- 戦闘ステージ：1pt
- ボスステージ：2pt

### マップ解放
- 累計距離（正確には「到達した最大距離」）が `requiredDistance` を超えるとステージが解放
- 1kmごとに1ステージ
- 履歴を削除しても `maxReachedDistance` は減らないので、一度解放したステージは閉じない

### バトル
- ターン制。攻撃・防御・スキルの3択
- 攻撃：通常ダメージ（いつでも可）
- 防御：次の敵攻撃を半減
- スキル：1.5倍ダメージ（SP制・1戦闘3回まで）
- 勝つと経験値を獲得し、たまるとレベルアップしてステータス上昇

### キャラ育成
- レベルアップで HP+20・攻撃+3・防御+2
- 次レベルに必要な経験値は `レベル × 100`

---

## 今後の拡張候補（未実装）

- 敵キャラの画像表示
- ショップと装備（ポイントの使い道を増やす）
- 敵のバリエーション増加（ステージごとに違う敵）

---

*このメモはアプリの構造を後から見返すための覚え書きです。コードを変更したら、対応する箇所も更新すると保守しやすくなります。*
