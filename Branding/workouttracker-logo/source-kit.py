import math
NAVY="#0A2850"; GREEN="#32D46B"; INK="#111318"; WHITE="#FFFFFF"
def doc(b,t,vb="0 0 256 256",w=256,h=256): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}" role="img" aria-labelledby="title"><title id="title">{t}</title>{b}</svg>\n'
# geometry (before centring): W = 4 points, climbing stroke from gap to a higher end
W=[(44,84),(86,196),(128,112),(170,196)]; TOP=(170+164/math.tan(math.radians(75)),32)
def along(p,q,d):
    dx,dy=q[0]-p[0],q[1]-p[1]; L=math.hypot(dx,dy); return (p[0]+dx*d/L,p[1]+dy*d/L)
def mark(c=INK, acc=None, sw=36, gap=84, dx=-5, dy=12):
    acc=acc or c; s=along(W[3],TOP,gap)
    pts=" L".join(f"{x+dx:.1f} {y+dy:.1f}" for x,y in W)
    return (f'<g id="w"><path d="M{pts}" fill="none" stroke="{c}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"/></g>'
            f'<g id="climb"><path d="M{s[0]+dx:.1f} {s[1]+dy:.1f} L{TOP[0]+dx} {TOP[1]+dy}" fill="none" stroke="{acc}" stroke-width="{sw}" stroke-linecap="round"/></g>')
def small(c=INK, acc=None): return mark(c,acc,sw=42,gap=96)
def icon(bg, c, acc, scale=0.72, grad=False):
    d='<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="256" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#0E3A72"/><stop offset="1" stop-color="#071A36"/></linearGradient></defs>' if grad else ""
    fill="url(#bg)" if grad else bg
    return doc(f'{d}<rect width="256" height="256" fill="{fill}"/><g transform="translate(128 128) scale({scale}) translate(-128 -128)">{mark(c,acc)}</g>',"WorkoutTracker app icon","0 0 256 256",1024,1024)
def lockup(c, acc, wc):
    # wordmark set in SF Pro Rounded (system font). Not outlined: see README.
    t=f'<text x="296" y="162" font-family="SF Pro Rounded, -apple-system, system-ui, sans-serif" font-weight="700" font-size="104" letter-spacing="-2" fill="{wc}">WorkoutTracker</text>'
    return doc(f'<g id="symbol">{mark(c,acc)}</g>{t}',"WorkoutTracker logo","0 0 1100 256",1100,256)
if __name__=="__main__":
    o="kit"
    open(f"{o}/wt-symbol-color.svg","w").write(doc(mark(NAVY,GREEN),"WorkoutTracker logo"))
    open(f"{o}/wt-symbol-on-dark.svg","w").write(doc(mark(WHITE,GREEN),"WorkoutTracker logo"))
    open(f"{o}/wt-symbol.svg","w").write(doc(mark(),"WorkoutTracker logo"))
    open(f"{o}/wt-symbol-small.svg","w").write(doc(small(NAVY,GREEN),"WorkoutTracker logo (small sizes)"))
    open(f"{o}/wt-horizontal-color.svg","w").write(lockup(NAVY,GREEN,NAVY))
    open(f"{o}/wt-horizontal-on-dark.svg","w").write(lockup(WHITE,GREEN,WHITE))
    open(f"{o}/wt-appicon-light.svg","w").write(icon(NAVY,WHITE,GREEN,grad=True))
    open(f"{o}/wt-appicon-dark.svg","w").write(icon("#000000",WHITE,GREEN))
    open(f"{o}/wt-appicon-tinted.svg","w").write(icon("#000000","#D9D9D9","#D9D9D9"))
    print("ok")
