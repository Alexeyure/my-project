third-task-третье задание в моём проекте, здесь мне было необходимо спроектировать систему мониторинга.

На сервере с prometheus необходимо оставить 22 порт для подключения по ssh b и разрешить входящие соединения на порт Prometheus 9090

В данном задании я создал два деб пакета, а именно: 
my-node-exporter-conf_0.1-1_all.deb данный дебпакет устанавливает консфигурационные файлы node-exporter, чтобы настроить сбор и отправку метрик на удалённый сервер с prometheus.
my-prometeus-conf_0.1-1_all.deb данный дебпакет несёт в себе консфигурационные файлы my-prometheus.yml(содержит в себе все необхоимые настройки косфигурации) и my-alertmanager.yml (содержит в себе шаблон настройки консфигурации для отправки сработавших алертов на электронную почту gmail.com)

Эти эти дебпакеты будут установлены после срабатывания скрипта ./script-prometheus.sh
Данный скрипт выполняет установку и настройку мониторингового сервера prometheus и устанвливает дебпакеты.

После выполнения скрипта необходимо в файле /etc/openvpn/my-alertmanager.yml заменить шаблонные данные на свои.


Для мониторинга OpenVpn сервера я написал следующие алерты:

(1) Проверка на работы VPN сервера, алерт сработает, если метрика up, которая указывает на доступность цели для мониторинга, становится равной 0, что может указывать на недоступность VPN сервера.
groups:
  - name: vpn_alerts
    rules:
      - alert: VPNServerDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "VPN Server Unreachable"
          description: "The VPN server is not responding to ICMP ping"



(2) Алерт сработает при чрезмерной нагрузке CPU
groups:
  - name: cpu_alerts
    rules:
      - alert: HighCPUUsage
        expr: node_cpu_seconds_total{mode="idle"} < 10
        for: 5m
        labels:
          severity: critical
          group: cpu_alerts
        annotations:
          summary: High CPU usage detected
          description: CPU usage is below 10% on node {{ $labels.instance }}



(3) Алерт сработает при большом количестве VPN соединений 
groups:
  - name: vpn_alerts
    rules:
      - alert: VPNConnectionsHigh
        expr: openvpn_clients_connected > 50
        for: 10m
        labels:
          severity: warning
          group: vpn_alerts
        annotations:
          summary: High number of VPN connections
          description: Number of VPN connections is above 50



(4) Алерт сработает при чрезмерном использовании памяти
groups:
  - name: memory_alerts
    rules:
      - alert: HighMemoryUsage
        expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 20
        for: 5m
        labels:
          severity: warning
          group: memory_alerts
        annotations:
          summary: High Memory usage detected
          description: Memory usage is above 80% on node {{ $labels.instance }}



(5) Алерт сработает при проблемах с подключением к VPN серверу
groups:
  - name: server_alerts
    rules:
      - alert: ServerConnectivityIssue
        expr: probe_success == 0
        for: 2m
        labels:
          severity: critical
          group: server_alerts
        annotations:
          summary: Server connectivity issue
          description: Probe to server failed, connectivity issue detected



(6)  Алерт сработает при высоком сетевом трафике
groups:
  - name: network_alerts
    rules:
      - alert: HighNetworkTraffic
        expr: sum(rate(node_network_transmit_bytes_total[1m])) > 1G
        for: 5m
        labels:
          severity: warning
          group: network_alerts
        annotations:
          summary: High Network Traffic detected
          description: Network traffic exceeds 1Gbps on node {{ $labels.instance }}



(7)  Алерт сработает при скором истечении срока SSL сертификата
groups:
  - name: ssl_alerts
    rules:
      - alert: SSLCertificateExpiry
        expr: ssl_cert_expiry{issuer="MyCA", common_name="example.com"} < time() + 30*24*60*60
        for: 1d
        labels:
          severity: warning
          group: ssl_alerts
        annotations:
          summary: SSL certificate expiry warning
          description: SSL certificate for example.com issued by MyCA will expire in less than 30 days



(8)  Алерт сработает при изменениях в конфигурационных файлах
groups:
  - name: config_alerts
    rules:
      - alert: ConfigChangeDetected
        expr: config_modified == 1
        for: 5m
        labels:
          severity: critical
          group: config_alerts
        annotations:
          summary: Configuration change detected
          description: Configuration file has been modified



(9)  Алерт сработает при большом количестве неудачных попыток входа в OpenVPN сервер
groups:
  - name: openvpn_alerts
    rules:
      - alert: OpenVPNFailedLogins
        expr: sum by (server) (openvpn_failed_logins_total) > 10
        for: 5m
        labels:
          severity: critical
          group: openvpn_alerts
        annotations:
          summary: Detecting high number of failed logins on OpenVPN
          description: There have been more than 10 failed logins on OpenVPN server {{ $labels.server }} in the last 5 minutes



(10) Алерт сработает при неудачном резервном копировании 
groups:
  - name: backup_updates_alerts
    rules:
      - alert: BackupAndUpdatesStatus
        expr: backup_success{job="backup_job"} == 0 or updates_needed{job="update_checker"} == 1
        for: 1h
        labels:
          severity: critical
          group: backup_updates_alerts
        annotations:
          summary: Backup or Updates Status Issue
          description: Backup job failed or updates are needed. Please investigate immediately.
