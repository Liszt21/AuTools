import requests
from bs4 import BeautifulSoup

def IPLocator(ip):
    url = "https://ip.cn/?ip="+ip
    heads = {}
    heads['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.221 Safari/537.36 SE 2.X MetaSr 1.0'
    r=requests.get(url,headers=heads)
    soup=BeautifulSoup(r.text,'html.parser')
    result=soup.find_all("div",id="result")
    return result.string

if __name__ == "__main__":
    print(IPLocator("69.85.89.158"))