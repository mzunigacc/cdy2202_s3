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
          set -e

          # Red
          docker network create ${NET} 2>/dev/null || true

          # MySQL: crear si no existe / iniciar si existe
          if docker ps -a --format '{{.Names}}' | grep -q "^${MYSQL_CONT}$"; then
            docker start ${MYSQL_CONT} >/dev/null || true
          else
            docker run -d --name ${MYSQL_CONT} --network ${NET} \
              -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
              -e MYSQL_DATABASE=${MYSQL_DB} \
              -p 3306:3306 \
              mysql:8.0
          fi

          # Esperar MySQL ready
          echo "Esperando MySQL READY..."
          for i in {1..60}; do
            if docker exec ${MYSQL_CONT} mysqladmin ping -uroot -p${MYSQL_ROOT_PASSWORD} --silent; then
              echo "OK: MySQL listo"
              break
            fi
            sleep 2
          done

          # Validación extra: mostrar BD
          docker exec -i ${MYSQL_CONT} mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;" || true

          # Tomcat: recrear siempre (app)
          docker rm -f ${TOMCAT_CONT} 2>/dev/null || true
          docker run -d --name ${TOMCAT_CONT} --network ${NET} \
            -p 9090:8080 ${APP_IMAGE}

          docker ps
        '''
      }
    }

    stage('Smoke Test (OpenAPI + Swagger)') {
      steps {
        sh '''
          set -e
          echo "Esperando a que levante la app..."

          # 1) Probar OpenAPI (más confiable)
          for i in {1..80}; do
            code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/vehiculosBuild/api-docs || true)
            echo "api-docs intento $i -> HTTP $code"
            if [ "$code" = "200" ]; then
              echo "OK: OpenAPI disponible"
              break
            fi
            sleep 2
          done

          # Si sigue fallando, mostrar logs y fallar
          code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/vehiculosBuild/api-docs || true)
          if [ "$code" != "200" ]; then
            echo "ERROR: OpenAPI no respondió 200"
            docker logs --tail 200 tomcat || true
            exit 1
          fi

          # 2) Probar Swagger UI (si existe)
          code_sw=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/vehiculosBuild/swagger-ui/index.html || true)
          echo "swagger-ui/index.html -> HTTP $code_sw"

          code_sw2=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/vehiculosBuild/swagger-ui.html || true)
          echo "swagger-ui.html -> HTTP $code_sw2"

          echo "Smoke test OK."
        '''
      }
    }
  }
}
