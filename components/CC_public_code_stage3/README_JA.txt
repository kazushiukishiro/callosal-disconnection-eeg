第3段階：WTC感度解析の公開用関数・合成データ試験

今回は新しいフォルダーで run_synthetic_sensitivity_demo を実行します。
第1・第2段階の試験は繰り返しません。
患者EDF、COREのMAT、臨床Excelを選択する画面はありません。
研究フォルダーやbase workspaceを検索・参照しません。

対象：LOO、患者クラスタを再抽出してLMMを再フィットするbootstrap、logit-WTC。
この関数化は新しいコードです。元の実行履歴・コードに基づいていますが、
「原著の最終実行スクリプトとバイト単位で同一」ではありません。
出所、変更範囲、未確認事項をdocs/SOURCE_PROVENANCE.mdに記載しています。

今回のbootstrapは動作確認用に50回です。
供給済み元コードの既定値2000回を論文用に変更する作業ではありません。
短縮テストのCIを論文のCIへ転記しないでください。
これまでのdwPLIの10000回paired-patient bootstrapとも別の処理です。

終了後：SHARE_STAGE3_REPORT.txtだけをこの会話へ添付してください。
PASS / REVIEW_REQUIRED / FAIL のいずれでも加工せず添付します。
LOCAL_DIAGNOSTICS.txtや合成CSVは、今回は添付不要です。

こちらの作成環境にはMATLAB本体がありません。
検査の事前成功や、臨床32例の結果再現を主張するものではありません。
確認が済むまでは、このZIPをGitHubへ追加せずPrivateのままにしてください。
