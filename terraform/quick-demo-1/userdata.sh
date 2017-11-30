#cloud-config
runcmd:
 - mkdir /srv/api
 - cd /srv/api
 - git clone -n https://github.com/lazyfunctor/cloudcourse.git --depth 1
 - cd cloudcourse
 - git checkout HEAD cmd/api/api
 - git checkout HEAD cmd/api/hello.service
 - cd /srv
 - chown -R www-data:www-data api
 - cp /srv/api/cloudcourse/cmd/api/hello.service /etc/systemd/system/hello.service
 - systemctl start hello.service