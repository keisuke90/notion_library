# NotionLibrary

![image](https://github.com/keisuke90/notion_library/assets/79405582/c2b86483-d981-4b29-a3fd-7c9a7442a8db)

NotionLibrary は Notion に読書記録をつけるための CLI です。

## 機能

1. Notion のデータベースに読んだ本を登録する

![image](https://github.com/keisuke90/notion_library/assets/79405582/08a68d3c-ada6-40ec-9ad7-af06885515d9)

2. Kindle のハイライトを取得する

![image](https://github.com/keisuke90/notion_library/assets/79405582/788ff9f1-81d8-40b4-b708-867da52be6b8)

## インストール方法

gem として公開していないため、本リポジトリをローカルに clone するか、Github からインストールしてください。

Github からインストールする方法

```bash
gem install specific_install
gem specific_install -l https://github.com/keisuke90/notion_library
```

## 準備

1. Notion のデータベース作成

   データベースを作成し、次のプロパティを設定してください。

   ```
   - Title(title)
   - Author(text)
   - Publisher(text)
   - ISBN(number)
   - ASIN(text)
   ```

2. 環境変数の登録

   次のコマンドで環境変数を登録します。

   ```bash
   notion_library init_secret
   ```

   以下の入力が必要になります。

   ```
    RAKUTEN_APP_ID = 楽天ウェブサービスのアプリID
    NOTION_SECRET = Notionのインテグレーションシークレット
    NOTION_DATABASE_ID = NotionのデータベースID
    AMAZON_EMAIL = Amazonログイン用メールアドレス
    AMAZON_PASSWORD = Amazonログイン用のパスワード
   ```

## 使い方

1. 本を登録する

   ```
   notion_library register
   ```

2. ハイライトを取得する

   ※Amazon の商品ページから ASIN を確認し、ASIN プロパティへの入力が必要です。

   ```
   notion_library highlight
   ```
