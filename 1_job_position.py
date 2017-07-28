import requests
from bs4 import BeautifulSoup
# import re
from lxml import etree
import ast
import json
import pandas as pd
import csv

client = requests.Session()

HOMEPAGE_URL = 'https://www.linkedin.com'
LOGIN_URL = 'https://www.linkedin.com/uas/login-submit'

html = client.get(HOMEPAGE_URL).content
soup = BeautifulSoup(html, "lxml")
csrf = soup.find(id="loginCsrfParam-login")['value']

login_information = {
    'session_key': 'rz992@nyu.edu',
    'session_password': '448702380',
    'loginCsrfParam': csrf,
}
client.post(LOGIN_URL, data=login_information)

job_list=pd.read_csv('jobinformation_data%20analyst_United%20States.csv')

job_details=[]

for i in job_list['5_joblinks']:
    url=i
    response = client.get(url)
    html=etree.HTML(response.content)

    result=html.xpath('//code[last()-4]/@id')
    #print result
    text='//code[@id=\"'+result[0]+'\"]/text()'
    #print (text)
    result2=html.xpath(text)

    # change to string type

    result3 = result2[0].encode('utf-8')
    result4 = json.loads(result3)

    print result4.keys()

    #print result4['description'].keys()

    #filtered_dict = {k:v for (k,v) in result4.items() if 'description' in k}
    if 'description' in result4:
        job_details.append(result4['description']['text'])
    else:
        job_details.append('None')

index=len(job_list['5_joblinks'])
data_frame=pd.DataFrame()

for y in range(index):
    data_frame=data_frame.append({'1_jobid': str(job_list['1_job_id'][y]), "2_jobtitles":job_list['2_jobtitles'][y],'3_company':job_list['3_Company'][y],
                        "4_jobdetials":job_details[y]},ignore_index=True)
print data_frame

data_frame.to_csv('jobdetails2' + '.csv', sep=',' ,encoding='utf-8')







