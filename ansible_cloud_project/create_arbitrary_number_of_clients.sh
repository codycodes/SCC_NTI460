#!/bin/bash

# Build a YAML configuration file for Ansible arbitrary num of clients

echo "---
 - name: Create instance(s)
   hosts: localhost
   connection: local
   gather_facts: no

   vars:
     service_account_email: account@developer.gserviceaccount.com
     credentials_file: /path/certification.json
     project_id: project-x-154804
     zone: us-west1-a
     machine_type: n1-standard-1
     image1: centos-7
     image2: ubuntu-1604-lts

   tasks:
   - name: Launch instance server
     gce:
         instance_names: ldap
         zone: \"{{ zone }}\"
         machine_type: \"{{ machine_type }}\"
         image: \"{{ image1 }}\"
         image_family: \"{{ image1 }}\"
         service_account_email: \"{{ service_account_email }}\"
         credentials_file: \"{{ credentials_file }}\"
         project_id: \"{{ project_id }}\"
         tags: ldap-server
         metadata: '{\"startup-script\" : \"curl https://raw.githubusercontent.com/yolmant/Ansible/master/Servers_config/Ldaps.bash > ldap.sh; chmod +x ./ldap.sh; ./ldap.sh\"}'
     register: gce

   - debug: msg=\" Ldap server IP = {{ gce.instance_data[0].private_ip }}\"

   - name: adding instances to the groups
     lineinfile:
       dest: /etc/ansible/hosts
       insertafter: '^\[ldap-server\]'
       line: \"{{ gce.instance_data[0].private_ip }}\"
       state: present

   - name: Launch NFS server
     gce:
        instance_names: nfs
        zone: \"{{ zone }}\"
        machine_type: \"{{ machine_type }}\"
        image: \"{{ image1 }}\"
        image_family: \"{{ image1 }}\"
        service_account_email: \"{{ service_account_email }}\"
        credentials_file: \"{{ credentials_file }}\"
        project_id: \"{{ project_id }}\"
        tags: nfs-server
        metadata: '{\"startup-script\" : \"curl https://raw.githubusercontent.com/yolmant/Ansible/master/Servers_config/NFS.bash > nfs.sh; chmod +x ./nfs.sh; ./nfs.sh\"}'
     register: gce

   - debug: msg=\" NFS server IP = {{ gce.instance_data[0].private_ip }}\"

   - name: adding instance to the groups
     lineinfile:
       dest: /etc/ansible/hosts
       insertafter: '^\[nfs-server\]'
       line: \"{{ gce.instance_data[0].private_ip }}\"
       state: present" >> ~/ansible_configuration

function create_clients {
 echo "- name: Launch Client
   gce:
      instance_names: client$1
      zone: \"{{ zone }}\"
      machine_type: \"{{ machine_type }}\"
      image: \"{{ image2 }}\"
      image_family: \"{{ image2 }}\"
      service_account_email: \"{{ service_account_email }}\"
      credentials_file: \"{{ credentials_file }}\"
      project_id: \"{{ project_id }}\"
      tags: clients
      metadata: '{\"startup-script\" : \"curl https://raw.githubusercontent.com/yolmant/Ansible/master/Servers_config/Clients.bash > config.sh; chmod +x ./config.sh; ./config.sh\"}'
   register: gce

 - debug: msg=\" Client IP = {{ gce.instance_data[0].private_ip }}\"

 - name: adding instance to the groups
   lineinfile:
     dest: /etc/ansible/hosts
     insertafter: '^\[clients\]'
     line: \"{{ gce.instance_data[0].private_ip }}\"
     state: present" >> ~/ansible_configuration

}

echo how many clients would you like Ansible to create?
read number_of_clients # stores the user input in a variable
for client_machine in $(seq 1 $number_of_clients);
do
 create_clients $client_machine;
done
