require "fileutils"

DEVELOPMENT_PATH = "docker/development"
VERSION_PATH = "#{DEVELOPMENT_PATH}/.version"

if !Dir.exists? DEVELOPMENT_PATH
  FileUtils.mkpath DEVELOPMENT_PATH
end

def format_image_name(image_name)
  return "" if !File.exists? VERSION_PATH
  "#{image_name}:#{File.read(VERSION_PATH).chomp}"
end

def docker_container_names
  `docker ps -q --filter ancestor=#{docker_image_name}`.split("\n")
end

def docker_container_name
  docker_container_names[0]
end

def docker_shell_command
  "/bin/ash"
end

def docker_start_command
  "docker run -d -v #{Dir.pwd}:/app -t #{docker_image_name}"
end

def uid
  `id -u`.chomp
end

def gid
  `id -g`.chomp
end

task :console, "Run a console inside the container" do
  call :exec, docker_shell_command, interactive: true
end

task :docker_build, "Build the container" do
  if !File.exists?(VERSION_PATH)
    call :docker_update
    next
  end
  if !system("docker image inspect #{docker_image_name} >/dev/null")
    shell "docker build -t #{docker_image_name} docker"
    puts
  end
end

task :docker_update, "Update the version and rebuild the container" do
  call :docker_stop
  old_version = File.read(VERSION_PATH).chomp if File.exists? VERSION_PATH
  File.write(VERSION_PATH, SecureRandom.hex)
  begin
    shell "docker build -t #{docker_image_name} docker"
    puts
    puts "Be careful to run `docker system prune -a -f` regularly when working ".yellow +
         "on a Dockerfile image because the Docker cache can grow exponentially.".yellow
  rescue
    next if old_version.nil?
    puts
    puts "The image build failed: rollback to the previous version.".red
    File.write(VERSION_PATH, old_version)
  end
end

task :docker_start, "Start the dev container" do
  if docker_container_name.nil?
    call :docker_build
    shell docker_start_command
    puts
  end
end

task :docker_stop, "Stop the dev container" do |*arguments, **options|
  if docker_container_names.size != 0
    puts
    docker_container_names.each do |name|
      puts "Stopping #{name}...".yellow
      `docker stop #{name} #{options[:immediate] == false ? "" : "-t 0"}`
    end
  end
end

task :docker_fix_rights, "Fix right issues" do
  puts
  message = "Please enter your sudo password if requested. It is to fix permissions\n" + \
            "on files modified from the docker container."
  puts message.yellow
  `sudo chown -R #{uid}:#{gid} .`
end

task :exec, "Execute a command inside the container" do |*arguments, **options|
  if arguments.size < 1
    puts "Too few arguments passed".red
    next
  end
  call :docker_start
  command = arguments.join(" ")
  command = options[:as].nil? ? command : "su -c '#{command}' #{options[:as]}"
  interactive = options[:interactive].nil? ? "" : "-i"
  command = "docker exec -t #{interactive} -w /app #{docker_container_name} #{command}"
  if options[:silent] === true
    `#{command}`
  else
    shell command
    puts
  end
end

task :exec_as, "Execute a command inside the container as another user" do |user, *arguments|
  call :exec, *arguments, as: user
end
