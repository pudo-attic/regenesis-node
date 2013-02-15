
request = require 'request'


# https://www-genesis.destatis.de:443/genesis/online/data/41331-0001.csv;jsessionid=6B0AEAB49D1F56FE39ACDFFF38F7E1A6.tomcat_GO_2_1?
# operation=ergebnistabelleDownload&levelindex=3&levelid=1360794663771&option=csv&doDownload=csv&contenttype='csv'
#

req = 
  form: 
    operation: 'ergebnistabelleDownload'
    levelindex: 3
    levelid: 1360794663771
    option: 'csv'
    doDownload: 'csv'
    contenttype: 'csv'

request.post 'https://www-genesis.destatis.de:443/genesis/online/data/41331-0001.csv;jsessionid=6B0AEAB49D1F56FE39ACDFFF38F7E1A6.tomcat_GO_2_1',
  
