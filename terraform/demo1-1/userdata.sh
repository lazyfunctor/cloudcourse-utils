#cloud-config
runcmd:
 - mkdir /srv/api
 - cd /srv/api
 - git clone -n https://github.com/lazyfunctor/cloudcourse.git --depth 1
 - cd cloudcourse
 - git checkout HEAD cmd/api/api
 - git checkout HEAD cmd/api/api.service
 - cd /srv
 - chown -R www-data:www-data api
 - cp /srv/api/cloudcourse/cmd/api/api.service /etc/systemd/system/api.service
 - systemctl start api.service