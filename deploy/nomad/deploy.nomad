job "deploy" {
  datacenters = ["dc1"]

  type = "service"

  # Specify this job to have rolling updates, two-at-a-time, with
  # 30 second intervals.
  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "database" {
    count = 1

    task "mongo" {
      driver = "docker"

      config {
        image = "mongo:4.1"

        port_map {
          mongo = 27017
        }
        
        volume_driver = "pxd"

        sysctl {
          "net.core.somaxconn" = "16384"
        }

        ulimit {
          nofile = "262144"
        }
      }

      logs {
        max_files     = 2
        max_file_size = 50
      }

      resources {
        cpu    = 1000
        memory = 1024

        network {
          mbits = 100
          port "mongo" {}
        }
      }

      # Controls the timeout between signalling a task it will be killed
      # and killing the task. If not set a default is used.
      kill_timeout = "20s"
    }
  }
}