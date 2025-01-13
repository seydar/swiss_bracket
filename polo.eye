Eye.config do
  logger '/home/ari/servers/eye.log'
end

ADDR = "127.0.0.1"
PORT = 4005

PID_FILE = "tmp/puma.pid"

Eye.app 'polo' do
  working_dir File.expand_path(File.dirname(__FILE__))

  process 'polo' do
    pid_file PID_FILE
    daemonize true

    start_command "thin -R config.ru -a #{HOST} -p #{PORT} -P tmp/thin.pid -l logs/thin.log start"
    stdall 'logs/default.log'

    stop_signals [:TERM, 10.seconds]

    restart_command 'kill -USR2 {PID}'

    check :cpu,    :every => 30, :below => 80, :times => 3
    check :memory, :every => 30, :below => 60.megabytes, :times => [3, 5]

    trigger :flapping, :times => 10, :within => 1.minute

    start_timeout 80.seconds
    restart_grace 30.seconds

    monitor_children do
      stop_command 'kill -QUIT {PID}'
      check :cpu,    :every => 30, :below => 80, :times => 3
      check :memory, :every => 30, :below => 60.megabytes, :times => [3, 5]
    end
  end
end
