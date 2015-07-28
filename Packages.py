packages = [['A',100,8,'Sun'],['B',150,5,'Sun'],['C',200,4,'Thu']]
weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
amounts = [50, 75, 75, 75, 50, 50, 50, 50, 100, 100, 100, 60, 60, 60, 60]
# For this example, the first amount is for Tuesday, 28th of July 2015

from datetime import datetime

weekdaysAmounts = [weekdays[w%6+1] for w in range(len(amounts))]
#print "weekdaysAmounts: "+str(weekdaysAmounts)

def sum_amount(startdate, enddate):
	dateformat = "%d/%m/%Y"
	start = datetime.strptime(startdate, dateformat)
	end = datetime.strptime(enddate, dateformat)
	amountDate = datetime.strptime('28/07/2015', dateformat)
	
	duration = (end-start).days+1
	fromStart = (start-amountDate).days
	
	costList = amounts[fromStart:fromStart+duration]
	daysList = weekdaysAmounts[fromStart:fromStart+duration]
	normalCost = sum(amounts[fromStart:fromStart+duration])
	print "Standard Cost: "+str(normalCost)
	#print str(daysList)
	priority = {}
	for package in packages:
		name, cost, dur, beginday = package
		priority[name] = cost*1.0/dur
	priority = sorted(priority.items(), key=lambda tuple: tuple[1])
	
	pId = 0
	packageCost = 0
	s=0
	while True:
		curPackage, cost, dur, day = filter(lambda x:x[0]==priority[pId][0],packages)[0]
		
		try:
			id = daysList[s:].index(day)
		except ValueError:
			if pId+1 == len(priority):
				break
			else:
				pId += 1
				continue

		if id+dur > duration:
			if pId+1 == len(priority):
				s = 0
				break
			else:
				pId += 1
		else:
			if any(len(d)==1 for d in daysList[id:id+dur]):
				s = 
			daysList[id:id+dur] = curPackage
			costList[id:id+dur] = [cost]
			print daysList
			print costList
			packageCost = sum(costList)
			print packageCost
	
	
	if packageCost == 0 or packageCost > normalCost:
		return normalCost
	else:
		return packageCost

	
	
#print sum_amount('29/07/2015','02/08/2015') # 29th Jul to 2nd Aug
print sum_amount('29/07/2015','10/08/2015') # 29th Jul to 10th Aug
