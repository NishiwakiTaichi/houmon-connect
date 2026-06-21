Rails.application.configure do
  # Pumaプロセス内のスレッドでジョブを非同期実行する(別プロセス・別サービス不要)
  config.good_job.execution_mode = :async

  # 同時実行ジョブスレッド数。Render無料(WEB_CONCURRENCY=1, RAILS_MAX_THREADS=5)では
  # Pumaのコネクションプールを圧迫しないよう2を基本とする
  config.good_job.max_threads = ENV.fetch("GOOD_JOB_MAX_THREADS", 2).to_i

  # LISTEN/NOTIFY を無効化する。
  # 有効時はNotifierがDBコネクションをプール外に1本保持し続けるため、
  # Render無料プランの起動時接続競合の原因になる。
  # 無効化後はpollingのみでジョブを検知する(最大poll_interval秒の遅延が生じるが
  # Chatwork通知用途では許容範囲)。
  config.good_job.enable_listen_notify = false

  # polling間隔(秒)。LISTEN/NOTIFY無効化に伴いジョブ検知をpollingのみに頼るため
  # 30秒から15秒に短縮して遅延を補う。
  config.good_job.poll_interval = 15

  # Puma終了時にジョブスレッドが現在実行中のジョブを完了するまで待つ最大秒数
  # Render のデプロイ停止猶予(grace period)より短くする
  config.good_job.shutdown_timeout = 25
end
