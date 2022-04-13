# Run extensions

A set of useful extensions for the [Run task manager](https://github.com/pyrsmk/run).

## Docker extension

> Requires Run v1.0.0.

```rb
require_extension "docker_v1.0.0"
```

This extension aims to ease Docker development container management with the following tasks:

- `console`: opens a Ash shell session inside the container (the official shell for Alpine Linux); if you want to spawn a different shell, you can define a `docker_shell_name` function and return the path to the needed shell command
- `docker_start`: starts the container if not yet started; this task runs `docker_build` automatically
- `docker_stop`: stops the container if not stopped
- `docker_fix_rights`: fix owner permissions in the current directory recursively (useful when your commands are run by root in your container, which is often the case)
- `docker_build`: builds the image if it does not exist yet
- `docker_update`: update the image version and rebuilds it
- `exec <command>`: execute an arbitrary command inside the container
- `exec_as <user> <command>`: execute an arbitrary command inside the container with the specified user
- `silent_exec <command>`: execute an arbitrary command inside the container (silent)
- `silent_exec_as <user> <command>`: execute an arbitrary command inside the container with the specified user (silent)

To use theses tasks, you'll need to define these functions in your Runfile:

- `docker_image_name`: returns the name you want for your image; the current version of the image will be appended to that name and the full image name will be available from `image_name` function
- `docker_start_command`: returns the command to use to start the container (default: `shell "docker run -d -v #{Dir.pwd}:/app -t #{docker_image_name}"`)
- `docker_shell_name`: returns the shell path you want to use when running `run console` (default: `/bin/ash`)

For example:

```rb
def docker_image_name
  # Wraping the image name with `format_image_name` is mandatory. It appends the current
  # version number of the image and process some verifications beforehand.
  format_image_name("namespace/project")
end

def docker_start_command
  # Replace the default command so we can bind `4000` port.
  shell "docker run -d -p 4000:4000 -v #{Dir.pwd}:/app -t #{image_name}"
end
```

> When a Run task needs the Docker development container to run, add `call :docker_start` at the top of it to ensure that the image is built and the container is running.

> You can also access the computed docker container name from `docker_container_name` function. You could need this to being able to run some commands like `docker exec`.

### Folder structure

```
|
-- docker/
  |
  -- development/: the files for the development Dockerfile
    |
    -- .version: the version of the current dev image
  |
  -- deployment/: the files for the deployment Dockerfile
  |
  -- Dockerfile: the development Dockerfile
|
-- Dockerfile: the deployment Dockerfile
```

> Node: the deployment Dockerfile is for production environments as staging or anything else where you need to deploy you application.

You may wonder why the Dockerfiles aren't placed inside their related directories. This is because of two things :

- some hosting services expect to find the deployment Dockerfile at the root of your project
- a Dockerfile is scoped to the directory where it's executed; hence if the development Dockerfile (for example) would be located inside `docker/development/` it couldn't access a file or a directory located in `docker/`

## Development

### Prerequisites

You'll need to install Bundler with `gem install bundler` because the Runfile need some gems to be installed with `bundle install`.

### Publish

To being able to publish to the CDN you'll need to create a `.env` file and define the `SPACES_SECRET` variable.
