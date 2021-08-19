---
title: "Firebase HostingでBasic認証をかける ~TypeScript編~"
emoji: "🔑"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [Firebase, TypeScript]
published: true
---

開発中だから見られたくない、特定の人にだけ見せたいなどで簡単に認証かけたいとなるとBasic認証である。

Firebase HostingでもCloud Functionsと連携すれば実現できる。

# ググるといっぱい出てくるが...

https://www.google.com/search?q=firebase+hosting+basic認証

なぜかCloud FunctionsはJavaScriptベースしか出てこなかった。
TypeScriptでやろうとしてちょっとハマったので共有していく。

:::message
見つけられなかっただけかも...
:::

# 手順

とは言え特別にやることはない。

:::message
Firebaseの初回セットアップは適当に済ましておいてね
:::

## ステップ 1

TypeScriptでも使えるBasic認証のパッケージを入れる。
[express\-basic\-auth \- npm](https://www.npmjs.com/package/express-basic-auth)

```sh
npm i express-basic-auth
```

## ステップ 2

Firebase Hostingデフォルトの`public/index.html`を削除して空にする。
ただし、`public`ディレクトリ自体は必要なので`.gitkeep`作って消えないようにしておく。

## ステップ 3

Basic認証かけたいページの諸々を`functions/web/`に配置する。
名称は`web`じゃなくてもなんでもいいが、後述の`functions/src/index.ts`中で参照しているのと同じ名前にしよう。

## ステップ 4

次のように、Functionsの`/app`にリクエストが来たら認証挟んで`functions/web/index.html`をレスポンスするように実装する。

:::message
ポイントとしては`../`が必要なこと。
愚直にJS版を参考にしてたら404になってハマった。
:::

:::message
もう1つのポイントとしては`challenge: true`
これがないとブラウザでアクセスした時にID/パスワード入力のポップアップが出てこなくて401になる。
:::

```typescript:functions/src/index.ts
import * as functions from "firebase-functions";
import * as express from "express";
import * as path from "path";
import * as basicAuth from "express-basic-auth";

const app = express();
app.use(
  basicAuth({
    challenge: true,
    users: {
      admin: "admin",
    },
  })
);
app.use(express.static(path.join(__dirname, "../", "web")));

app.use((req, res) => {
  res.sendFile(path.join(__dirname, "../", "web", "index.html"));
});

exports.app = functions.https.onRequest(app);
```

## ステップ 5

`rewrites`を追加する。

```diff:firebase.json
  "hosting": {
    "public": "public",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
+   "rewrites": [
+     {
+       "source": "**",
+       "function": "app"
+     }
    ]
  },
```

## ステップ 6

```sh
firebase deploy
```

## 最終的にはこのような構成になる

```
/hoge/
|--firebase.json
|
|-- functions
|   |-- web
|   |   `-- index.html
|   `-- src
|       `-- index.ts
`-- public
    `-- .gitkeep
```

# まとめ

これでめでたくBasic認証かけられた。
静的なページはもちろん、Flutter WebなどのSPAでも問題ない。

が、これって毎回Cloud Functions叩く事になるので遅いし、Cloud Functionsの実行コストもかかるので実用的かと言われると。.。
