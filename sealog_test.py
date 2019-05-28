import json
import sys
import datetime

sys.path.append('.')

from sealog import Sealog

Sealog = Sealog()

### Get all the cruise objects in Sealog
print( Sealog.getCruises() )
cruises = Sealog.getCruises()['cruises']
for cruise in cruises:
  print(json.dumps(cruise, indent=2))

### Get the cruise object for a specific oid
cruise = Sealog.getCruiseByOID('5b97997d97607e04c75b1561')
print(json.dumps(cruise, indent=2))

### Get the cruise object for a specific cruiseID
cruise = Sealog.getCruiseByID('AT42-01')
print(json.dumps(cruise, indent=2))

### Get all the lowering objects in Sealog
lowerings = Sealog.getLowerings()['lowerings']
for lowering in lowerings:
  print(json.dumps(lowering, indent=2))

### Get the lowering object for a specific oid
lowering = Sealog.getLoweringByOID('5b04121392faed46c5aa8fb5')
print(json.dumps(lowering, indent=2))

### Get the lowering object for a specific loweringID
lowering = Sealog.getLoweringByID('J2-1107')
print(json.dumps(lowering, indent=2))

### Get the start/stop times for a specific loweringID
lowering = Sealog.getLoweringByID('J2-1107')
print("Start:", lowering['start_ts'])
print("Stop:", lowering['stop_ts'])

### Get the dive duration for a specific loweringID
lowering = Sealog.getLoweringByID('J2-1107')
start = datetime.datetime.strptime(lowering['start_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
stop = datetime.datetime.strptime(lowering['stop_ts'], "%Y-%m-%dT%H:%M:%S.%fZ")
print("Duration:", stop-start)

## Get the lowering objects for a specific cruise based on a cruiseID
lowerings = Sealog.getLoweringsForCruise('AT42-01')['lowerings']
print(json.dumps(lowerings, indent=2))

### Build a cruise selection dialog
cruises = Sealog.getCruises()['cruises']
print("Available Cruises:")
print("--------------")
for index, cruise in enumerate(cruises):
    print(index+1, ':', cruise['cruise_id'])
print(len(cruises)+1, ':', "Quit")

selected_index = None
while selected_index == None:
    print("\nSelect a cruise:")
    select = None
    try:
        index = int(input())-1
        if index <= len(cruises):
            selected_index = index
        elif index > len(cruises):
            print('\nInvalid selection! Please try again.')
            continue
    except:
        print('\nInvalid selection! Please try again...')
        continue

if selected_index == len(cruises):
    print("Quitting...")
    sys.exit(0)

print("\nSelected index:", selected_index)
print("Selected cruise", cruises[selected_index]['cruise_id'])
 
### Build a lowering selection dialog for a specific cruise
cruiseID = 'AT42-01'
lowerings = Sealog.getLoweringsForCruise(cruiseID)['lowerings']
print("Available Lowerings for cruise", cruiseID + ":")
print("--------------")
for index, lowering in enumerate(lowerings):
    print(index+1, ':', lowering['lowering_id'])
print(len(lowerings)+1, ':', "Quit")


selected_index = None
while selected_index == None:
    print("\nSelect a lowering:")
    select = None
    try:
        index = int(input())-1
        if index <= len(lowerings):
            selected_index = index
        elif index > len(lowerings):
            print('\nInvalid selection! Please try again.')
            continue
    except:
        print('\nInvalid selection! Please try again...')
        continue

if selected_index == len(lowerings):
    print("Quitting...")
    sys.exit(0)

print("\nSelected index:", selected_index)
print("Selected lowering", lowerings[selected_index]['lowering_id'])