"""Demo workouts for README screenshots: eight weeks of Push/Pull/Bein with rising weights, plus walks,
rides and runs. Dates are relative to today. Usage: demo-workouts.py [output.json]"""
import json, uuid, datetime as dt, random
random.seed(7)
REF = dt.datetime(2001,1,1,tzinfo=dt.timezone.utc)
now = dt.datetime.now().astimezone()
def ts(d): return (d - REF).total_seconds()
def sets(n, reps, w): return [{"id":str(uuid.uuid4()).upper(),"reps":reps,"weight":w,"isCompleted":True} for _ in range(n)]
def ex(name, n, reps, w): return {"id":str(uuid.uuid4()).upper(),"name":name,"sets":sets(n,reps,w)}
PLAN = {
 "Push": [("Benkpress",4,6,70),("Skulderpress",3,8,40),("Incline benkpress",3,10,24),("Triceps pushdown",3,12,25),("Lateral raises",3,15,8)],
 "Pull": [("Markløft",3,5,110),("Pull-ups",4,8,0),("Sittende roing",3,10,55),("Facepull",3,15,20),("Bicep curl",3,12,12)],
 "Bein": [("Squat",4,6,90),("Strak markløft",3,8,80),("Leg press",3,10,160),("Leg curl",3,12,40),("Planke",3,1,0)],
}
workouts=[]; rot=["Push","Pull","Bein"]; k=0
start = (now - dt.timedelta(days=55)).replace(hour=17, minute=30, second=0, microsecond=0)
day = start
while day.date() < now.date():
    wd = day.weekday()
    if wd in (0,2,4) or (wd==5 and random.random()<0.5):
        t = rot[k%3]; prog = (day-start).days/55
        exs=[ex(n,s,r, round((w*(1+0.12*prog))/2.5)*2.5 if w else 0) for n,s,r,w in PLAN[t]]
        workouts.append({"id":str(uuid.uuid4()).upper(),"date":ts(day.replace(hour=random.choice([7,17,18]))),"type":t,"category":"Styrke","exercises":exs,"notes":"","duration":random.randint(50,75)*60})
        k+=1
    if wd in (1,6) and random.random()<0.7:
        cat,typ = random.choice([("Gange","Gange"),("Sykling","Sykling"),("Løping","Løping")])
        workouts.append({"id":str(uuid.uuid4()).upper(),"date":ts(day.replace(hour=12)),"type":typ,"category":cat,"exercises":[],"notes":"","duration":random.randint(25,70)*60})
    day += dt.timedelta(days=1)
# a session earlier today
workouts.append({"id":str(uuid.uuid4()).upper(),"date":ts(now.replace(hour=7,minute=15)),"type":rot[k%3],"category":"Styrke","exercises":[ex(n,s,r,round((w*1.13)/2.5)*2.5 if w else 0) for n,s,r,w in PLAN[rot[k%3]]],"notes":"Ny rekord!","duration":3900})
import sys
json.dump(workouts, open(sys.argv[1] if len(sys.argv) > 1 else "workouts.json", "w"))
print(len(workouts), "workouts")
