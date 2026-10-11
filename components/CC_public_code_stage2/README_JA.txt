【v2：構文エラー修正版】
cc_synthetic_group_fixture.mの59行目で不足していた閉じ括弧1個を追加しました。
他のMATLABコード・乱数seed・合成データ設定・モデル式・検査条件は変更していません。
ZIPは CC_public_code_stage2_v2.zip、展開後のルートは CC_public_code_stage2 です。
新しいフォルダーへ展開し、第2段階だけを再実行してください。
SHA256SUMS.txtも更新済みです。チェックを削除・無効化しないでください。
MATLAB本体での修正版の実行結果は、まだ確認していません。

第2段階：集団レベルの集計・統計解析インターフェースの合成データ試験

1. このフォルダーで run_synthetic_group_demo を実行してください。
2. 研究フォルダー、患者EDF、COREのMAT、臨床Excelは選びません。
3. Statistics and Machine Learning Toolboxが必要です。
4. 架空24名のepochレベル集計表をその場で生成します。
   前回の合成EDFから計算した結果を読み込むものではありません。
5. 今回のLMMのフィットとbootstrapは、新しい合成データだけが対象です。
   32例の臨床解析や保存済みモデルは再実行・再保存しません。
6. group_demo_outputの新しいサブフォルダーに結果が保存されます。
   SHARE_STAGE2_REPORT.txtだけを返送してください。
   LOCAL_DIAGNOSTICS.txtはローカルパスを含み得るため送信不要です。
7. STATUS: PASSはここに列挙した合成テストの成功です。
   REVIEW_REQUIREDなら警告確認が必要です。FAILなら停止箇所が記録されます。
   チェックや閾値を変更して通す作業はしません。
8. MATLAB本体での実行は作成環境では未確認です。
9. このセットをまだGitHubへアップロードしたりReleaseにしないでください。
   論文全体の公開用コードの完成版ではありません。
10. 第1段階のPASS記録はvalidation/STAGE1_REPORT.txtに保持しています。
    Stage1の元ZIP・元コードは変更していません。

今回未実施：患者データとの結果照合、実際の最終除外リスト、
LOO、患者クラスタを再標本化してLMMを再フィットするbootstrap、
clinical-modifier LMM、臨床順位検定、追跡適格性、図の出力、
1000/2000-Hz EDFの読込試験。

保存済みpost hoc解析コードの19個の数値処理関数をそのまま再利用し、
新しい実行入口、合成集計表、出所別指標計算、地域別対比の構成を追加しました。
関数化した全体が元研究のスクリプトと同一、という主張はしていません。


【v3】
採用epochが0件の場合の比較を、配列の向きによらず行うようテスト側を修正しました。
srcの4ファイル、採用基準、合成集計表の生成、モデル式はv2から変更していません。
修正版は新しいフォルダーへ展開し、同じrun_synthetic_group_demoを実行します。
今回のSHARE_STAGE2_REPORT.txtを確認するまで、第2段階をPASSとは扱いません。
