packages = [['A',100,8,'Sun'],['B',150,5,'Sun'],['C',200,4,'Thu']]
weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
amounts = [50, 75, 75, 75, 50, 50, 50, 50, 100, 100, 100, 60, 60, 60, 60, 75, 75, 75, 50, 50, 50, 50, 100, 100, 100, 60, 60, 60, 60]
# For this example, the first amount is for Tuesday, 28th of July 2015

from datetime import datetime

# Here convert the amounts to a list of weekdays
weekdaysAmounts = [weekdays[w%6+1] for w in range(len(amounts))]
#print "weekdaysAmounts: "+str(weekdaysAmounts)

def sum_amount(startdate, enddate):
  dateformat = "%d/%m/%Y"
  start = datetime.strptime(startdate, dateformat)
  end = datetime.strptime(enddate, dateformat)
  amountDate = datetime.strptime('28/07/2015', dateformat)
  
  # Get duration of stay or whatever
  duration = (end-start).days+1
  # Get where the stay starts from the amounts list
  fromStart = (start-amountDate).days
  
  # Get cost sublist
  costList = amounts[fromStart:fromStart+duration]
  # Get weekdays sublist
  daysList = weekdaysAmounts[fromStart:fromStart+duration]
  # Calculate normal cost
  normalCost = sum(costList)
  print "Standard Cost: "+str(normalCost)
  #print str(daysList)
  
  # Decide which package to prioritize
  priority = {}
  for package in packages:
    name, cost, dur, beginday = package
    priority[name] = cost*1.0/dur
  priority = sorted(priority.items(), key=lambda tuple: tuple[1])
  
  # Package index
  pId = 0
  # Cost using packages
  packageCost = 0
  # variable to prevent package overriding
  s=0
  while True:
    curPackage, cost, dur, day = filter(lambda x:x[0]==priority[pId][0],packages)[0]

    
    # If day within weekday list, get its first index
    try:
      id = daysList[s:].index(day) + s
    # else continue with next package
    except ValueError:
      if pId+1 >= len(priority):
        break
      else:
        pId += 1
        continue
    
    # If package length is not within duration of stay, continue with next package
    if id+dur > duration:
      if pId+1 == len(priority):
        s = 0
        break
      else:
        pId += 1
    # else...
    else:
      # If package in selection, find next available days after first package
      test = [len(d) for d in daysList[id:id+dur]]
      if 1 in test:
        s = test.index(1)+id
        continue
      # else calculate the cost with that package
      duration -= (dur-1)
      daysList[id:id+dur] = curPackage
      costList[id:id+dur] = [cost]
      #print daysList
      #print costList
      packageCost = sum(costList)
      print daysList
      print packageCost

  
  
  if packageCost == 0 or packageCost > normalCost:
    return normalCost
  else:
    return packageCost

#print sum_amount('29/07/2015','02/08/2015') # 29th Jul to 2nd Aug
#print sum_amount('29/07/2015','10/08/2015') # 29th Jul to 10th Aug
print sum_amount('29/07/2015','16/08/2015') # 29th Jul to 16th Aug
