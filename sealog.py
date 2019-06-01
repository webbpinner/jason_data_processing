import json
import requests
from constants import serverURL, token


class Sealog():

  def __init__(self):

    self.serverURL = serverURL
    self.token = token

    self.headers = {
      "authorization": self.token
    }

  ############################
  def getLowerings(self):
    url = self.serverURL + '/api/v1/lowerings'
    r = requests.get(url, headers=self.headers)

    if r.status_code != 200:
      return { "error": r.text }

    else:
      return { "lowerings": json.loads(r.text)}

  ############################
  def getLoweringByOID(self, oid):
    url = self.serverURL + '/api/v1/lowerings/' + oid
    r = requests.get(url, headers=self.headers)

    if r.status_code == 200:
      return json.loads(r.text)

    elif r.status_code == 404:
      return None

    else:
      return { "error": json.loads(r.text) }

  ############################
  def getLoweringByID(self, loweringID):
    url = self.serverURL + '/api/v1/lowerings?lowering_id=' + loweringID
    r = requests.get(url, headers=self.headers)

    if r.status_code == 200:
      return json.loads(r.text)[0]

    elif r.status_code == 404:
      return None

    else:
      return { "error": json.loads(r.text) }

  ############################
  def getCruises(self):
    url = self.serverURL + '/api/v1/cruises'
    r = requests.get(url, headers=self.headers)

    if r.status_code == 200:
        return { "cruises": json.loads(r.text) }

    elif r.status_code == 404:
        return { "cruises": [] }

    else:
        return { "error": json.loads(r.text) }

  ############################
  def getCruiseByOID(self, oid):
    url = self.serverURL + '/api/v1/cruises/' + oid
    r = requests.get(url, headers=self.headers)

    if r.status_code == 200:
      return json.loads(r.text)

    elif r.status_code == 404:
      return None

    else:
      return { "error": json.loads(r.text) }

  ############################
  def getCruiseByID(self, cruiseID):
    url = self.serverURL + '/api/v1/cruises?cruise_id=' + cruiseID
    r = requests.get(url, headers=self.headers)
    print(url)
    print(r.text)


    if r.status_code == 200:
      return json.loads(r.text)[0]

    elif r.status_code == 404:
      return None

    else:
      return { "error": json.loads(r.text) }

  ############################
  def getLoweringsForCruise(self, cruiseID):
    cruises = self.getCruises()

    cruise = list(filter(lambda cruise: cruise['cruise_id'] == cruiseID, cruises['cruises']))

    if len(cruise) == 0:
      return None
    else:
      url = self.serverURL + '/api/v1/lowerings?startTS=' + cruise[0]['start_ts'] + '&stopTS=' + cruise[0]['stop_ts']
      r = requests.get(url, headers=self.headers)

      if r.status_code == 200:
        return { "lowerings": json.loads(r.text) }

      elif r.status_code == 404:
        return { "lowerings": [] }

      else:
        return { "error": json.loads(r.text) }

  ### Build a cruise selection dialog
  def build_cruise_select_menu(self, defaultID=None, newest=False):
    cruises = self.getCruises()['cruises']

    if len(cruises) == 0:
      print("\nNo Cruises available")
      return None

    print("\nAvailable Cruises:")
    print("------------------")

    default_index = None
    default_prompt = ''
    if(newest and len(cruises) > 0):
      default_index = 0
      default_prompt = ' (' + cruises[0]['cruise_id'] + ') '

    for index, cruise in enumerate(cruises):
      if default_index == None and defaultID == cruise['cruise_id']:
        default_index = index
        default_prompt = ' (' + cruise['cruise_id'] + ') '
      print(str(index+1) + ':', cruise['cruise_id'])
    print('q:', "Quit\n")

    cruise_index = None
    while cruise_index == None:
        print("Select a cruise" + default_prompt + ":", end =" ")
        #select = None
        try:
            raw_select = input()
            if not raw_select:
              cruise_index = default_index
            elif raw_select == 'q':
              return None
            else:
                selected_index = int(raw_select)-1
                if selected_index < len(cruises):
                    cruise_index = selected_index
                else:
                    print('\nInvalid selection! Please try again.')
        except:
            print('\nInvalid selection! Please try again...')
            continue

    # print("Selected cruise", cruises[cruise_index]['cruise_id'])
    return cruises[cruise_index]

  ### Build a lowering selection dialog
  def build_lowering_select_menu(self, cruiseID, defaultID=None, newest=False):
    lowerings = self.getLoweringsForCruise(cruiseID)['lowerings']

    if len(lowerings) == 0:
      print("\nNo Lowerings available for", cruiseID + ":")
      return None

    print("\nAvailable Lowerings for", cruiseID + ":")
    print("------------------------------")

    default_index = None
    default_prompt = ''
    if(newest and len(lowerings) > 0):
      default_index = 0
      default_prompt = ' (' + lowerings[0]['lowering_id'] + ') '

    for index, lowering in enumerate(lowerings):
        if default_index == None and defaultID == lowering['lowering_id']:
          default_index = index
          default_prompt = ' (' + lowering['lowering_id'] + ') '
        print(str(index+1) + ':', lowering['lowering_id'])
    print('q:', "Quit\n")

    lowering_index = None
    while lowering_index == None:
        print("Select a lowering" + default_prompt + ":", end =" ")
        #select = None
        try:
            raw_select = input()
            if not raw_select:
                lowering_index = default_index
            elif raw_select == 'q':
                return None
            else:
                selected_index = int(raw_select)-1
                if selected_index < len(lowerings):
                    lowering_index = selected_index
                else:
                    print('\nInvalid selection! Please try again.')
        except:
            print('\nInvalid selection! Please try again...')
            continue

    # print("Selected lowering", lowerings[lowering_index]['lowering_id'])
    return lowerings[lowering_index]
