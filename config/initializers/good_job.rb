Rails.application.configure do
  # Pumaプロセス内のスレッドでジョブを非同期実行する(別プロセス・別サービス不要)
  config.good_job.execution_mode = :async

  # 同時実行ジョブスレッド数。Render無料(WEB_CONCURRENCY=1, RAILS_MAX_THREADS=5)では
  # Pumaのコネクションプールを圧迫しないよう2を基本とする
  config.good_job.max_threads = ENV.fetch("GOOD_JOB_MAX_THREADS", 2).to_i

  # DB polling間隔(秒)。新着ジョブはNOTIFY/LISTENで即時検知するためpollingは補助
  config.good_job.poll_interval = 30

  # Puma終了時にジョブスレッドが現在実行中のジョブを完了するまで待つ最大秒数
  # Render のデプロイ停止猶予(grace period)より短くする
  config.good_job.shutdown_timeout = 25
end
