#cloud-config
runcmd:
 - mkdir /srv/api
 - cd /srv/api
 - git clone -n https://github.com/lazyfunctor/cloudcourse.git --depth 1
 - cd cloudcourse
 - git checkout HEAD cmd/api/api
 - git checkout HEAD cmd/api/cpu.service
 - cd /srv
 - chown -R www-data:www-data api
 - cp /srv/api/cloudcourse/cmd/api/cpu.service /etc/systemd/system/cpu.service
 - systemctl start cpu.service