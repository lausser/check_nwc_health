Auf meiner Startseite steht:

I will ignore all of your mails unless you give me an ip address and a community/root account. No joke! No exception!

Herrschaften, das ist durchaus ernst gemeint. Freibier ist alle! Und wenn ich eine Mail zur Kenntnis nehme, dann bedeutet das immer noch nicht, daß ich für lau eure Arbeit mache. 

Description
============
The plugin check_nwc_health was developed with the aim of having a single tool for all aspects of monitoring of network components.


Motivation
==========
Instead of installing a variety of plug-ins for monitoring of interfaces, hardware, bandwidth, sessions, pools, etc. and possibly more than one for each brand, with check_nwc_health you need only one a single plugin.

Documentation
=============

Command line parameters
-----------------------

* --hostname
* --community
* --mode

Modi
----

| Mode                          | Function                                                               |
|-------------------------------|------------------------------------------------------------------------|
| hardware-health               | Check the status of environmental equipment (fans, temperatures, power) |
| cpu-load                      | Check the CPU load of the device |
| memory-usage                  | Check the memory usage of the device |
| interface-usage               | Check the utilization of interfaces |
| interface-errors              | Check the error-rate of interfaces  |
| interface-discards            | Check the discard-rate of interfaces |
| interface-status              | Check the status of interfaces (oper/admin) |
| interface-nat-count-sessions  | Count the number of nat sessions |
| interface-nat-rejects         | Count the number of nat sessions rejected due to lack of resources) |
| list-interfaces               | Show the interfaces of the device and update the name cache |
| list-interfaces-detail        | Show the interfaces of the device and some details |
| interface-availability        | Show the availability (oper != up of interfaces) |
| link-aggregation-availability | Check the percentage of up interfaces in a link aggregation |
| list-routes                   | Check the percentage of up interfaces in a link aggregation |
| route-exists                  | Check if a route exists. (--name is the dest, --name2 check also the next hop) |
| count-routes                  | Count the routes. (--name is the dest, --name2 is the hop) |
| vpn-status                    | Check the status of vpns (up/down) |
| create-shinken-service        | Create a Shinken service definition |
| hsrp-state                    | Check the state in a HSRP group) |
| hsrp-failover                 | Check if a HSRP group's nodes have changed their roles |
| list-hsrp-groups              | Show the HSRP groups configured on this device |
| bgp-peer-status               | Check status of BGP peers |
| list-bgp-peers                | Show BGP peers known to this device |
| ospf-neighbor-status          | Check status of OSPF neighbors |
| list-ospf-neighbors           | Show OSPF neighbors |
| ha-role                       | Check the role in a ha group |
| svn-status                    | Check the status of the svn subsystem |
| mngmt-status                  | Check the status of the management subsystem |
| fw-policy                     | Check the installed firewall policy |
| fw-connections                | Check the number of firewall policy connections |
| session-usage                 | Check the session limits of a load balancer |
| security-status               | Check if there are security-relevant incidents |
| pool-completeness             | Check the members of a load balancer pool |
| pool-connections              | Check the number of connections of a load balancer pool |
| pool-complections             | Check the members and connections of a load balancer pool |
| list-pools                    | List load balancer pools |
| check-licenses                | Check the installed licences/keys |
| count-users                   | Count the (connected) users/sessions |
| check-config                  | Check the status of configs (cisco, unsaved config changes) |
| check-connections             | Check the quality of connections |
| count-connections             | Check the number of connections (-client, -server is possible) |
| watch-fexes                   | Check if FEXes appear and disappear (use --lookup) |
| accesspoint-status            | Check the status of access points |
| count-accesspoints            | Check if the number of access points is within a certain range |
| watch-accesspoints            | Check if access points appear and disappear (use --lookup) |
| list-accesspoints             | List access points managed by this device |
| phone-cm-status               | Check if the callmanager is up |
| phone-status                  | Check the number of registered/unregistered/rejected phones |
| list-smart-home-devices       | List Fritz!DECT 200 plugs managed by this device |
| smart-home-device-status      | Check if a Fritz!DECT 200 plug is on |
| smart-home-device-energy      | Show the current power consumption of a Fritz!DECT 200 plug |
| walk                          | Show snmpwalk command with the oids necessary for a simulation |
| supportedmibs                 | Shows the names of the mibs which this devices has implemented (only lausser may run this command) |

The list is not complete. Some devices that are not listed here can possibly be monitored because they implement the same MIBs as supported models. Just try it ....
(If a device is not recognized, i can extend the plugin. But not for free)

Installation
============

* git clone
* cd check_nwc_health
* git submodule update --init
* autoreconf
* ./configure
* make
* cp plugins-scripts/check_nwc_health wherever...

Examples
========

    # Hardware checks
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/asa5510
    OK - no alarms
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/c2900
    OK - no alarms, environmental hardware working fine
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/3500xl
    OK - no alarms, environmental hardware working fine
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/3750e
    OK - environmental hardware working fine | 'temp_1006'=27;60;;; 'temp_2006'=26;60;;; 'temp_3006'=26;60;;;
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/3750e --verbose
    I am a Cisco IOS Software, C3750E Software (C3750E-UNIVERSALK9-M), Version 12.2(58)SE2, RELEASE SOFTWARE (fc1) Technical Support: http://www.cisco.com/techsupport Copyright (c) 1986-2011 by Cisco Systems, Inc. Compiled Thu 21-Jul-11 01:23 by prod_rel_team
    OK - environmental hardware working fine
    checking fans
    fan 1059 (Switch#1, Fan#1) is normal
    fan 1060 (Switch#1, Fan#2) is normal
    fan 2060 (Switch#2, Fan#1) is normal
    fan 2061 (Switch#2, Fan#2) is normal
    fan 3036 (Switch#3, Fan#1) is normal
    fan 3037 (Switch#3, Fan#2) is normal
    checking temperatures
    temperature 1006 SW#1, Sensor#1, GREEN  is 27 (of 60 max = normal)
    temperature 2006 SW#2, Sensor#1, GREEN  is 26 (of 60 max = normal)
    temperature 3006 SW#3, Sensor#1, GREEN  is 26 (of 60 max = normal)
    checking voltages
    checking supplies
    powersupply 1058 (Sw1, PS1 Normal, RPS NotExist) is normal
    powersupply 1062 (Sw1, PS2 Normal, RPS NotExist) is normal
    powersupply 2058 (Sw2, PS1 Normal, RPS NotExist) is normal
    powersupply 2059 (Sw2, PS2 Normal, RPS NotExist) is normal
    powersupply 3034 (Sw3, PS1 Normal, RPS NotExist) is normal
    powersupply 3035 (Sw3, PS2 Normal, RPS NotExist) is normal | 'temp_1006'=27;60;;; 'temp_2006'=26;60;;; 'temp_3006'=26;60;;;
    
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/n5000
    OK - environmental hardware working fine | 'sens_celsius_100021590'=44;45;57;; 'sens_celsius_101021590'=41;45;57;; 'sens_celsius_21590'=44;50;60;; 'sens_celsius_21591'=46;50;60;; 'sens_celsius_21592'=33;50;60;; 'sens_celsius_21593'=34;50;60;; 'sens_celsius_21594'=34;40;50;; 'sens_celsius_21595'=33;40;50;; 'sens_celsius_21596'=33;50;60;; 'sens_celsius_21597'=31;50;60;; 'sens_celsius_21602'=38;50;60;;
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/n5000 --verbose
    I am a Cisco NX-OS(tm) n5000, Software (n5000-uk9), Version 4.2(1)N1(1), RELEASE SOFTWARE Copyright (c) 2002-2010 by Cisco Systems, Inc. Device Manager Version 5.0(1a),  Compiled 4/29/2010 19:00:00
    OK - environmental hardware working fine
    checking thresholds
    checking entities
    checking sensor_entities
    checking sensors
    celsius sensor 100021590 (Fex-100 Module-1 Outlet-1) is ok
    celsius sensor 100021591 (Fex-100 Module-1 Outlet-2) is unknown_10
    celsius sensor 100021592 (Fex-100 Module-1 Inlet-1) is unknown_10
    celsius sensor 101021590 (Fex-101 Module-1 Outlet-1) is ok
    celsius sensor 101021591 (Fex-101 Module-1 Outlet-2) is unknown_10
    celsius sensor 101021592 (Fex-101 Module-1 Inlet-1) is unknown_10
    celsius sensor 21590 (Module-1, Outlet-1) is ok
    celsius sensor 21591 (Module-1, Outlet-2) is ok
    celsius sensor 21592 (Module-1, Intake-1) is ok
    celsius sensor 21593 (Module-1, Intake-2) is ok
    celsius sensor 21594 (Module-1, Intake-3) is ok
    celsius sensor 21595 (Module-1, Intake-4) is ok
    celsius sensor 21596 (PowerSupply-1 Sensor-1) is ok
    celsius sensor 21597 (PowerSupply-2 Sensor-1) is ok
    celsius sensor 21602 (Module-2, Outlet-1) is ok
    checking fans
    fan/tray 100000534 (Fex-100 FanModule-1) status is up
    fan/tray 100000539 (Fex-100 PowerSupply-1 Fan-1) status is up
    fan/tray 100000540 (Fex-100 PowerSupply-2 Fan-1) status is up
    fan/tray 101000534 (Fex-101 FanModule-1) status is up
    fan/tray 101000539 (Fex-101 PowerSupply-1 Fan-1) status is up
    fan/tray 101000540 (Fex-101 PowerSupply-2 Fan-1) status is up
    fan/tray 534 (FanModule-1) status is up
    fan/tray 535 (FanModule-2) status is up
    fan/tray 536 (PowerSupply-1 Fan-1) status is up
    fan/tray 537 (PowerSupply-1 Fan-2) status is up
    fan/tray 538 (PowerSupply-2 Fan-1) status is up
    fan/tray 539 (PowerSupply-2 Fan-2) status is up
    checking entities
    checking powersupplygroups
    checking supplies
    checking entities
    checking powersupplies
    power supply 100000022 admin status is on, oper status is on
    power supply 100000470 admin status is on, oper status is on
    power supply 100000471 admin status is on, oper status is on
    power supply 101000022 admin status is on, oper status is on
    power supply 101000470 admin status is on, oper status is on
    power supply 101000471 admin status is on, oper status is on
    power supply 22 admin status is on, oper status is on
    power supply 23 admin status is on, oper status is on
    power supply 470 admin status is on, oper status is on
    power supply 471 admin status is on, oper status is on | 'sens_celsius_100021590'=44;45;57;; 'sens_celsius_101021590'=41;45;57;; 'sens_celsius_21590'=44;50;60;; 'sens_celsius_21591'=46;50;60;; 'sens_celsius_21592'=33;50;60;; 'sens_celsius_21593'=34;50;60;; 'sens_celsius_21594'=34;40;50;; 'sens_celsius_21595'=33;40;50;; 'sens_celsius_21596'=33;50;60;; 'sens_celsius_21597'=31;50;60;; 'sens_celsius_21602'=38;50;60;;
    
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/ucos
    OK - storage 10 (/partB) has 71.07% free space left, storage 11 (/spare) has 99.88% free space left, storage 3 (/) has 70.71% free space left, storage 7 (/common) has 69.07% free space left, storage 9 (/grub) has 95.87% free space left, environmental hardware working fine | '/partB_free_pct'=71.07%;10:;5:;0;100 '/spare_free_pct'=99.88%;10:;5:;0;100 '/_free_pct'=70.71%;10:;5:;0;100 '/common_free_pct'=69.07%;10:;5:;0;100 '/grub_free_pct'=95.87%;10:;5:;0;100
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/ucos --verbose
    I am a Hardware:VMware, 2  Intel(R) Xeon(R) CPU           E5640  @ 2.67GHz, 4096 MB Memory: Software:UCOS 4.0.0.0-45
    OK - storage 10 (/partB) has 71.07% free space left, storage 11 (/spare) has 99.88% free space left, storage 3 (/) has 70.71% free space left, storage 7 (/common) has 69.07% free space left, storage 9 (/grub) has 95.87% free space left, environmental hardware working fine
    checking storages
    storage 10 (/partB) has 71.07% free space left
    storage 11 (/spare) has 99.88% free space left
    storage 3 (/) has 70.71% free space left
    storage 7 (/common) has 69.07% free space left
    storage 9 (/grub) has 95.87% free space left | '/partB_free_pct'=71.07%;10:;5:;0;100 '/spare_free_pct'=99.88%;10:;5:;0;100 '/_free_pct'=70.71%;10:;5:;0;100 '/common_free_pct'=69.07%;10:;5:;0;100 '/grub_free_pct'=95.87%;10:;5:;0;100
    
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/cisco-3745-switch
    OK - environmental hardware working fine | 'temp_1005'=44;65;;;
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/cisco-3745-switch --verbose
    I am a Cisco IOS Software, 3700 Software (C3745-ADVENTERPRISEK9-M), Version 12.4(25b), RELEASE SOFTWARE (fc1)
    OK - environmental hardware working fine
    checking fans
    fan 1004 (Switch#1, Fan#1) is normal
    checking temperatures
    temperature 1005 SW#1, Sensor#1, GREEN  is 44 (of 65 max = normal)
    checking voltages
    checking supplies
    powersupply 1003 (Sw1, PS1 Normal, RPS NotExist) is normal | 'temp_1005'=44;65;;;
    
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/cisco-cat6509
    OK - environmental hardware working fine | 'temp_100050'=35;65;;; 'temp_100051'=36;65;;; 'temp_40010'=31;115;;; 'temp_40020'=34;115;;; 'temp_40030'=30;115;;; 'temp_60010'=45;85;;; 'temp_60011'=34;65;;; 'temp_60020'=30;95;;; 'temp_60021'=30;70;;; 'temp_60030'=35;100;;; 'temp_60031'=29;70;;; 'temp_60050'=43;85;;; 'temp_60051'=29;80;;; 'temp_60054'=62;105;;; 'temp_60055'=45;110;;; 'temp_60056'=57;110;;; 'temp_90010'=38;80;;; 'temp_90011'=33;75;;; 'temp_90050'=38;75;;; 'temp_90051'=31;65;;;
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community cisco/cisco-cat6509 --verbose
    I am a Cisco IOS Software, s72033_rp Software (s72033_rp-ADVIPSERVICES), Version 12.2(33)SXJ, RELEASE SOFTWARE (fc3) Technical Support: http://www.cisco.com/techsupport Copyright (c) 1986-2011 by Cisco Systems, Inc. Compiled Thu 17-Mar-11 15:10 by pro
    OK - environmental hardware working fine
    checking fans
    fan 1 ( Chassis Fan Tray 1) is normal
    fan 2 ( Power Supply 1 Fan) is normal
    fan 3 ( Power Supply 2 Fan) is normal
    checking temperatures
    temperature 100050 module 5 RP outlet temperature is 35 (of 65 max = normal)
    temperature 100051 module 5 RP inlet temperature is 36 (of 65 max = normal)
    temperature 40010 VTT 1 outlet temperature is 31 (of 115 max = normal)
    temperature 40020 VTT 2 outlet temperature is 34 (of 115 max = normal)
    temperature 40030 VTT 3 outlet temperature is 30 (of 115 max = normal)
    temperature 60010 module 1 outlet temperature is 45 (of 85 max = normal)
    temperature 60011 module 1 inlet temperature is 34 (of 65 max = normal)
    temperature 60020 module 2 outlet temperature is 30 (of 95 max = normal)
    temperature 60021 module 2 inlet temperature is 30 (of 70 max = normal)
    temperature 60030 module 3 outlet temperature is 35 (of 100 max = normal)
    temperature 60031 module 3 inlet temperature is 29 (of 70 max = normal)
    temperature 60050 module 5 outlet temperature is 43 (of 85 max = normal)
    temperature 60051 module 5 inlet temperature is 29 (of 80 max = normal)
    temperature 60054 module 5 asic-1 temperature is 62 (of 105 max = normal)
    temperature 60055 module 5 asic-3 temperature is 45 (of 110 max = normal)
    temperature 60056 module 5 asic-4 temperature is 57 (of 110 max = normal)
    temperature 90010 module 1 EARL outlet temperature is 38 (of 80 max = normal)
    temperature 90011 module 1 EARL inlet temperature is 33 (of 75 max = normal)
    temperature 90050 module 5 EARL outlet temperature is 38 (of 75 max = normal)
    temperature 90051 module 5 EARL inlet temperature is 31 (of 65 max = normal)
    checking voltages
    checking supplies
    powersupply 1 ( Power Supply 1, WS-CAC-3000W) is normal
    powersupply 2 ( Power Supply 2, WS-CAC-3000W) is normal | 'temp_100050'=35;65;;; 'temp_100051'=36;65;;; 'temp_40010'=31;115;;; 'temp_40020'=34;115;;; 'temp_40030'=30;115;;; 'temp_60010'=45;85;;; 'temp_60011'=34;65;;; 'temp_60020'=30;95;;; 'temp_60021'=30;70;;; 'temp_60030'=35;100;;; 'temp_60031'=29;70;;; 'temp_60050'=43;85;;; 'temp_60051'=29;80;;; 'temp_60054'=62;105;;; 'temp_60055'=45;110;;; 'temp_60056'=57;110;;; 'temp_90010'=38;80;;; 'temp_90011'=33;75;;; 'temp_90050'=38;75;;; 'temp_90051'=31;65;;;

    $ check_nwc_health --hostname 10.0.12.114 --mode chassis hardware-health --community cisco/cisco-cat6509 --verbose
    I am a Cisco IOS Software, s72033_rp Software (s72033_rp-ADVIPSERVICESK9_WAN-M), Version 12.2(33)SXJ, RELEASE SOFTWARE (fc3) Technical Support: http://www.cisco.com/techsupport Copyright (c) 1986-2011 by Cisco Systems, Inc. Compiled Thu 17-Mar-11 15:10 by pro
    WARNING - 4 new module(s) (SAL1536ZWYC, SAL1538HZF9, SAL1521S03A, SAL1528D536), 85 new ports, chassis sys status is ok, power supply 1 status is ok, power supply 2 status is ok, found 4 modules with 85 ports
    module 1 (serial SAL1536ZWYC) is ok
    module 2 (serial SAL1538HZF9) is ok
    module 3 (serial SAL1521S03A) is ok
    module 5 (serial SAL1528D536) is ok
    chassis sys status is ok
    chassis fan status is ok
    chassis minor alarm is off
    chassis major alarm is off
    chassis temperature alarm is off
    power supply 1 status is ok
    power supply 2 status is ok
    found 4 modules with 85 ports
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community foundry/ironware
    OK - environmental hardware working fine
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community foundry/ironware --verbose
    I am a Foundry Networks, Inc. Router, IronWare Version 10.2.01lTI4 Compiled on Oct 28 2009 at 16:46:07 labeled as WJR10201l
    OK - environmental hardware working fine
    checking powersupplies
    powersupply 1 is normal
    checking fans
    fan 1 is normal
    fan 2 is normal
    checking temperatures
    
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community f5/f5app
    CRITICAL - chassis fan 1 is unknown_3 (9642rpm), chassis fan 2 is unknown_3 (10227rpm), chassis fan 3 is unknown_3 (9642rpm) | 'temp_c1'=38;;;; 'fan_c1'=9926;;;; 'fan_1'=9642;;;; 'fan_2'=10227;;;; 'fan_3'=9642;;;; 'temp_1'=25;;;;
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community f5/f5app --verbose
    I am a Linux lb02 2.6.1-1.1.el5.1.0.f5app #1 SMP Mon Mar 5 12:40:48 PST 2012 x86_64
    CRITICAL - chassis fan 1 is unknown_3 (9642rpm), chassis fan 2 is unknown_3 (10227rpm), chassis fan 3 is unknown_3 (9642rpm)
    checking cpus
    cpu 1 has 38C (9926rpm)
    checking fans
    chassis fan 1 is unknown_3 (9642rpm)
    chassis fan 2 is unknown_3 (10227rpm)
    chassis fan 3 is unknown_3 (9642rpm)
    checking temperatures
    chassis temperature 1 is 25C
    checking powersupplies
    chassis powersupply 1 is good
    chassis powersupply 2 is notpresent
    checking disks | 'temp_c1'=38;;;; 'fan_c1'=9926;;;; 'fan_1'=9642;;;; 'fan_2'=10227;;;; 'fan_3'=9642;;;; 'temp_1'=25;;;;
    
    
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community bluecoat/bluecoat-proxy-sg
    OK - disk 0 usage is 35.00%, environmental hardware working fine | 'sensor_Motherboard temperature 1'=18.70;;;; 'sensor_+12V bus voltage'=12.13;;;; 'sensor_CPU core voltage'=1.10;;;; 'sensor_CPU +1.8V bus voltage'=1.81;;;; 'sensor_Motherboard temperature 2'=20.50;;;; 'sensor_CPU temperature'=28;;;; 'sensor_System Fan 1 speed'=8280;;;; 'sensor_System Fan 2 speed'=8400;;;; 'sensor_System Fan 3 speed'=9764.80;;;; 'sensor_System Fan 4 speed'=8460;;;; 'sensor_+2.5V bus voltage'=2.51;;;; 'sensor_+5V bus voltage'=5.07;;;; 'disk_0_usage'=35%;60;60;0;100
    $ 
    $ check_nwc_health --hostname 10.0.12.114 --mode hardware-health --community bluecoat/bluecoat-proxy-sg --verbose
    I am a Blue Coat ProxySG600
    OK - disk 0 usage is 35.00%, environmental hardware working fine
    sensor Motherboard temperature 1 (18.7 celsius) is ok
    sensor +12V bus voltage (12.13 volts) is ok
    sensor CPU core voltage (1.1 volts) is ok
    sensor CPU +1.8V bus voltage (1.81 volts) is ok
    sensor Motherboard temperature 2 (20.5 celsius) is ok
    sensor CPU temperature (28 celsius) is ok
    sensor System Fan 1 speed (8280 rpm) is ok
    sensor System Fan 2 speed (8400 rpm) is ok
    sensor System Fan 3 speed (9764.8 rpm) is ok
    sensor System Fan 4 speed (8460 rpm) is ok
    sensor +2.5V bus voltage (2.51 volts) is ok
    sensor +5V bus voltage (5.07 volts) is ok
    checking disks
    disk 1 (SEAGATE 0002) is present
    disk 2 ( ) is not-present
    checking filesystems
    disk 0 usage is 35.00% | 'sensor_Motherboard temperature 1'=18.70;;;; 'sensor_+12V bus voltage'=12.13;;;; 'sensor_CPU core voltage'=1.10;;;; 'sensor_CPU +1.8V bus voltage'=1.81;;;; 'sensor_Motherboard temperature 2'=20.50;;;; 'sensor_CPU temperature'=28;;;; 'sensor_System Fan 1 speed'=8280;;;; 'sensor_System Fan 2 speed'=8400;;;; 'sensor_System Fan 3 speed'=9764.80;;;; 'sensor_System Fan 4 speed'=8460;;;; 'sensor_+2.5V bus voltage'=2.51;;;; 'sensor_+5V bus voltage'=5.07;;;; 'disk_0_usage'=35%;60;60;0;100
    
    
    # CPU checks
    
    $ check_nwc_health --hostname 10.0.12.114 --mode cpu-load --community bluecoat/bluecoat-proxy-sg --verbose
    I am a Blue Coat ProxySG600
    OK - cpu 1 usage is 18.00%
    checking cpus
    cpu 1 usage is 18.00% | 'cpu_1_usage'=18%;80;90;0;100
    
    $ check_nwc_health --hostname 10.0.12.114 --mode cpu-load --community f5/f5app --verbose
    I am a Linux lb02 2.6.1-1.1.el5.1.0.f5app #1 SMP Mon Mar 5 12:40:48 PST 2012 x86_64
    OK - tmm cpu usage is 1.24%
    checking cpus
    tmm cpu usage is 1.24% | 'cpu_tmm_usage'=1.24%;80;90;0;100
    
    $ check_nwc_health --hostname 10.0.12.114 --mode cpu-load --community foundry/ironware --verbose
    I am a Foundry Networks, Inc. Router, IronWare Version 10.2.01lTI4 Compiled on Oct 28 2009 at 16:46:07 labeled as WHEJR64WH
    OK - cpu 1 usage is 6.00, cpu 1 usage is 1.90
    cpu 1 usage is 6.00
    cpu 1 usage is 1.90 | 'cpu_1'=6%;80;90;0;100 'cpu_1'=1.90%;80;90;0;100
    
    
    # Memory
    
    $ check_nwc_health --hostname 10.0.12.114 --mode memory-usage --community foundry/ironware --verbose
    I am a Foundry Networks, Inc. Router, IronWare Version 10.2.01lTI4 Compiled on Oct 28 2009 at 16:46:07 labeled as WHEJR64WH
    OK - memory usage is 23.00%
    checking memory
    memory usage is 23.00% | 'memory_usage'=23%;80;99;0;100
    
    $ check_nwc_health --hostname 10.0.12.114 --mode memory-usage --community bluecoat/bluecoat-proxy-sg --verbose
    I am a Blue Coat ProxySG600
    OK - memory usage is 17.00%
    checking memory
    memory usage is 17.00% | 'memory_usage'=17%;75;90;0;100
    
    $ check_nwc_health --hostname 10.0.12.114 --mode memory-usage --community cisco/n5000 --verbose
    I am a Cisco NX-OS(tm) n5000, Software (n5000-uk9), Version 4.2(1)N1(1), RELEASE SOFTWARE Copyright (c) 2002-2010 by Cisco Systems, Inc. Device Manager Version 5.0(1a),  Compiled 4/29/2010 19:00:00
    OK - memory usage is 53.00%
    checking memory
    memory usage is 53.00% | 'memory_usage'=53%;80;90;0;100
    
    $ check_nwc_health --hostname 10.0.12.114 --mode memory-usage --community cisco/asa5510 --verbose
    I am a Cisco Adaptive Security Appliance Version 9.1(5)
    WARNING - mempool MEMPOOL_DMA usage is 80.68%, mempool System memory usage is 29.78%, mempool MEMPOOL_GLOBAL_SHARED usage is 12.73%
    checking mems
    mempool System memory usage is 29.78%
    mempool MEMPOOL_DMA usage is 80.68%
    mempool MEMPOOL_GLOBAL_SHARED usage is 12.73% | 'System memory_usage'=29.78%;80;90;0;100 'MEMPOOL_DMA_usage'=80.68%;80;90;0;100 'MEMPOOL_GLOBAL_SHARED_usage'=12.73%;80;90;0;100
    
    
    # Interfaces
    
    $ check_nwc_health --hostname 10.0.12.114 --mode interface-usage --community checkpoint/fw-1 --verbose
    I am a Linux m-nm09 2.6.18-92cpx86_64 #1 SMP Tue Aug 14 06:41:50 IDT 2012 x86_64
    OK - interface lo usage is in:0.25% (24796.45Bits/s) out:0.25% (24796.45Bits/s), interface eth0 usage is in:0.00% (849.78Bits/s) out:0.00% (349.95Bits/s), interface eth1 usage is in:0.00% (1103.22Bits/s) out:0.00% (466.08Bits/s), interface eth2 usage is in:0.00% (0.00Bits/s) out:0.00% (0.00Bits/s) (down), interface eth3 usage is in:0.00% (0.00Bits/s) out:0.00% (0.00Bits/s) (down), interface bond1 usage is in:0.02% (1953.00Bits/s) out:0.01% (816.03Bits/s), interface sit0 usage is in:0.00% (0.00Bits/s) out:0.00% (0.00Bits/s) (down)
    checking interfaces
    interface lo usage is in:0.25% (24796.45Bits/s) out:0.25% (24796.45Bits/s)
    interface eth0 usage is in:0.00% (849.78Bits/s) out:0.00% (349.95Bits/s)
    interface eth1 usage is in:0.00% (1103.22Bits/s) out:0.00% (466.08Bits/s)
    interface eth2 usage is in:0.00% (0.00Bits/s) out:0.00% (0.00Bits/s) (down)
    interface eth3 usage is in:0.00% (0.00Bits/s) out:0.00% (0.00Bits/s) (down)
    interface bond1 usage is in:0.02% (1953.00Bits/s) out:0.01% (816.03Bits/s)
    interface sit0 usage is in:0.00% (0.00Bits/s) out:0.00% (0.00Bits/s) (down) | 'lo_usage_in'=0.25%;80;90;0;100 'lo_usage_out'=0.25%;80;90;0;100 'lo_traffic_in'=24796.45;8000000;9000000;0;10000000 'lo_traffic_out'=24796.45;8000000;9000000;0;10000000 'eth0_usage_in'=0.00%;80;90;0;100 'eth0_usage_out'=0.00%;80;90;0;100 'eth0_traffic_in'=849.78;800000000;900000000;0;1000000000 'eth0_traffic_out'=349.95;800000000;900000000;0;1000000000 'eth1_usage_in'=0.00%;80;90;0;100 'eth1_usage_out'=0.00%;80;90;0;100 'eth1_traffic_in'=1103.22;800000000;900000000;0;1000000000 'eth1_traffic_out'=466.08;800000000;900000000;0;1000000000 'eth2_usage_in'=0%;80;90;0;100 'eth2_usage_out'=0%;80;90;0;100 'eth2_traffic_in'=0;;;0;0 'eth2_traffic_out'=0;;;0;0 'eth3_usage_in'=0%;80;90;0;100 'eth3_usage_out'=0%;80;90;0;100 'eth3_traffic_in'=0;;;0;0 'eth3_traffic_out'=0;;;0;0 'bond1_usage_in'=0.02%;80;90;0;100 'bond1_usage_out'=0.01%;80;90;0;100 'bond1_traffic_in'=1953.00;8000000;9000000;0;10000000 'bond1_traffic_out'=816.03;8000000;9000000;0;10000000 'sit0_usage_in'=0%;80;90;0;100 'sit0_usage_out'=0%;80;90;0;100 'sit0_traffic_in'=0;;;0;0 'sit0_traffic_out'=0;;;0;0
    

Homepage
========

The full documentation can be found here:
[check_nwc_health @ ConSol Labs](http://labs.consol.de/nagios/check_nwc_health)
