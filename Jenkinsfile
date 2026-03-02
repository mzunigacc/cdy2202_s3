pipeline {
  agent any

  environment {
    APP_IMAGE = "sucursal-app:latest"
    NET = "cicd-net"
    MYSQL_CONT = "mysql"
    TOMCAT_CONT = "tomcat"
    MYSQL_ROOT_PASSWORD = "admin123"
    MYSQL_DB = "Sucursal"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build WAR') {
      steps {
        sh 'chmod +x mvnw'
        sh './mvnw clean package -DskipTests'
        sh 'ls -lah target/*.war'
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${APP_IMAGE} .'
      }
    }

    stage('Deploy (MySQL + Tomcat)') {
      steps {
        sh '''
          docker network create ${NET} 2>/dev/null || true

          # MySQL (crear solo si no existe)
          if ! docker ps -a --format '{{.Names}}' | grep -q "^${MYSQL_CONT}$"; then
            docker run -d --name ${MYSQL_CONT} --network ${NET} \
              -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
              -e MYSQL_DATABASE=${MYSQL_DB} \
              -p 3306:3306 \
              mysql:8.0
          fi

          # Tomcat (recrear siempre)
          docker rm -f ${TOMCAT_CONT} 2>/dev/null || true
          docker run -d --name ${TOMCAT_CONT} --network ${NET} \
            -p 9090:8080 ${APP_IMAGE}

          docker ps
        '''
      }
    }

    stage('Smoke Test (Swagger)') {
      steps {
        sh '''
          echo "Esperando a que levante Tomcat..."
          for i in {1..40}; do
            if curl -sSf http://localhost:9090/vehiculosBuild/swagger-ui/index.html >/dev/null; then
              echo "OK: Swagger disponible"
              exit 0
            fi
            sleep 2
          done
          echo "ERROR: No levantó Swagger"
          docker logs tomcat || true
          exit 1
        '''
      }
    }
  }
}
