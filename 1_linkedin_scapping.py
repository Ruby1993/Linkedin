import requests
from bs4 import BeautifulSoup
# import re
from lxml import etree
import ast
import json
import pandas as pd

client = requests.Session()


def ConstructURL(keyword, location, Page):
    url = "https://www.linkedin.com/jobs/search/?"

    return url + "keywords=" + keyword + "&location=" + location + "&start=" + Page


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

# identify 20 jobs on each page
page = 20
keyword = 'data%20analyst'
location = 'United%20States'
job = []
#return url + "keywords=" + keyword + "&location=" + location + "&start=" + Page
#https://www.linkedin.com/jobs/search/?keywords=data%20analyst&location=us%3A0&start=
#https://www.linkedin.com/jobs/search/?keywords=data%20analyst&locationId=us%3A0
for i in range(35):
    Page = str(page * i)
    url = ConstructURL(keyword, location, Page)
    response = client.get(url)
    html = etree.HTML(response.content)
    result = html.xpath('//code[last()-2]/@id')
    text = '//code[@id=\"' + result[0] + '\"]/text()'
    result2 = html.xpath(text)
    new = result2[0].encode('utf-8')
    new2 = json.loads(new)
    filtered_data = {k: v for (k, v) in new2.items() if 'elements' in k}
    for element in filtered_data['elements']:
        # del element['com.linkedin.voyager.search.FacetSuggestion']
        # print element['com.linkedin.voyager.search.SearchJobJserp']
        # print element['hitInfo'].keys()      list
        if element['hitInfo'].keys()[0] == 'com.linkedin.voyager.search.SearchJobJserp':
            job.append(element['hitInfo']['com.linkedin.voyager.search.SearchJobJserp'])

job_requirement = []
job_links = []
job_titles = []
job_company = []
job_location = []
token = len(job)

for a in job:
    # print a['jobPostingResolutionResult']
    # print a['jobPostingResolutionResult']['companyDetails']['com.linkedin.voyager.jobs.JobPostingCompany']['companyResolutionResult']['name']
    # print a['jobPostingResolutionResult']['companyDetails']['com.linkedin.voyager.jobs.JobPostingCompany']['companyResolutionResult'].keys()
    # print a['jobPostingResolutionResult']['title']
    # print a['jobPostingResolutionResult']['formattedLocation']
    # print  a['jobPostingResolutionResult']['applyMethod']
    # print  a['jobPostingResolutionResult']['details']
    # print a['jobPosting'][32:]

    job_requirement.append(a['descriptionSnippet'])
    job_links.append("https://www.linkedin.com/jobs/view/" + a['jobPosting'][32:])
    job_titles.append(a['jobPostingResolutionResult']['title'])
    job_location.append(a['jobPostingResolutionResult']['formattedLocation'])
    if 'com.linkedin.voyager.jobs.JobPostingCompany' in a['jobPostingResolutionResult']['companyDetails']:
        if 'companyResolutionResult' in a['jobPostingResolutionResult']['companyDetails']['com.linkedin.voyager.jobs.JobPostingCompany']:
            job_company.append(a['jobPostingResolutionResult']['companyDetails']['com.linkedin.voyager.jobs.JobPostingCompany']['companyResolutionResult']['name'])
        else:
            job_company.append('Null')
    else:
        job_company.append('Null')

final_frame = pd.DataFrame()

for i in range(token):
    final_frame = final_frame.append({"1_job_id": str(i), "2_jobtitles": job_titles[i], "3_Company": job_company[i],
                                      "4_Location": job_location[i],
                                      "5_joblinks": job_links[i],
                                      "6_requirement": job_requirement[i]},
                                     ignore_index=True)
print final_frame

final_frame.to_csv('jobinformation_'+keyword+'_'+location+'.csv',sep=',', encoding='utf-8')
