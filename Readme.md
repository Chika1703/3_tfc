# Домашнее задание к занятию «Безопасность в облачных провайдерах»  

Используя конфигурации, выполненные в рамках предыдущих домашних заданий, нужно добавить возможность шифрования бакета.

---
## Задание 1. Yandex Cloud   

1. С помощью ключа в KMS необходимо зашифровать содержимое бакета:

 - создать ключ в KMS;
 - с помощью ключа зашифровать содержимое бакета, созданного ранее.
2. (Выполняется не в Terraform)* Создать статический сайт в Object Storage c собственным публичным адресом и сделать доступным по HTTPS:

 - создать сертификат;
 - создать статическую страницу в Object Storage и применить сертификат HTTPS;
 - в качестве результата предоставить скриншот на страницу с сертификатом в заголовке (замочек).

Полезные документы:

- [Настройка HTTPS статичного сайта](https://cloud.yandex.ru/docs/storage/operations/hosting/certificate).
- [Object Storage bucket](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/storage_bucket).
- [KMS key](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kms_symmetric_key).

--- 
## Задание 2*. AWS (задание со звёздочкой)

Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.

**Что нужно сделать**

1. С помощью роли IAM записать файлы ЕС2 в S3-бакет:
 - создать роль в IAM для возможности записи в S3 бакет;
 - применить роль к ЕС2-инстансу;
 - с помощью bootstrap-скрипта записать в бакет файл веб-страницы.
2. Организация шифрования содержимого S3-бакета:

 - используя конфигурации, выполненные в домашнем задании из предыдущего занятия, добавить к созданному ранее бакету S3 возможность шифрования Server-Side, используя общий ключ;
 - включить шифрование SSE-S3 бакету S3 для шифрования всех вновь добавляемых объектов в этот бакет.

3. *Создание сертификата SSL и применение его к ALB:

 - создать сертификат с подтверждением по email;
 - сделать запись в Route53 на собственный поддомен, указав адрес LB;
 - применить к HTTPS-запросам на LB созданный ранее сертификат.

Resource Terraform:

- [IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role).
- [AWS KMS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key).
- [S3 encrypt with KMS key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object#encrypting-with-kms-key).

Пример bootstrap-скрипта:

```
#!/bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>My cool web-server</h1></html>" > index.html
aws s3 mb s3://mysuperbacketname2021
aws s3 cp index.html s3://mysuperbacketname2021
```

### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

---

### Введение

#### Т.к у меня нет доступа не к aws/yandex cloud, я буду использовать timeweb.cloud (модуль по тераформу принимали с провайдером [timeweb.cloud](https://github.com/Chika1703/terraform_hw/blob/main/02.1/Readme.md) ответ преподователя:)
![1](https://github.com/Chika1703/1_tfc/blob/main/img/1.jpg)

Интернет --> Load Balancer (185.233.187.132) --> LAMP Servers (192.168.30.10–12) --> выход в интернет через NAT Server (213.171.9.93) --> Object Storage

Запрос идёт на Load Balancer. Балансировщик распределяет трафик между всеми LAMP-серверами, чтобы нагрузка была равномерной.

Балансировщик перенаправляет запрос на один из LAMP-серверов в приватной сети (192.168.30.10–11).

LAMP-сервер формирует страницу. Если на странице есть ссылка на картинку из Object Storage, сервер обращается к интернету, чтобы получить её. Поскольку LAMP-серверы находятся в приватной сети, выход в интернет идёт через NAT-сервер (213.171.9.93).

LAMP-сервер получает картинку и отдаёт полностью сформированную страницу пользователю через балансировщик.

---

### Решение

создал приватный бакет
![4](https://github.com/Chika1703/3_tfc/blob/main/img/4.png)


подключил домен и сделал ssl сертификат 
![2](https://github.com/Chika1703/3_tfc/blob/main/img/2.png)
![3](https://github.com/Chika1703/3_tfc/blob/main/img/3.png)

зашел на сайт
![1](https://github.com/Chika1703/3_tfc/blob/main/img/1.png)