/* prof.jsx — 교수 플로우 */

const PST={att:['att','출석'],late:['late','지각'],none:['none','미처리'],err:['err','오류'],abs:['abs','결석']};
const RANK={err:0,late:1,none:2,abs:3,att:4};

function ProfHome(){
  const {st,set}=useApp();
  const cls=profClass(Date.now());
  return <div className="screen fade">
    <TopBar title="전자출결 교수" right={st.preset.name}/>
    <div className="card em" style={{flex:1,display:'flex',flexDirection:'column'}}>
      <div className="lbl">오늘의 강의</div>
      <div className="big">인간-컴퓨터 상호작용</div>
      <div className="small muted">공대 7호관 301호</div>
      <div className="small" style={{marginTop:2}}>{cls.start} ~ {cls.end}</div>
      <div className="grow"/>
      <div className="btn blue" style={{padding:16,fontSize:16}} onClick={()=>set({screen:'profStart'})}>출석 시작하기 →</div>
    </div>
    <div className="small muted" style={{margin:'2px 0 6px'}}>다음 강의</div>
    <div className="card" style={{opacity:.5,padding:'9px 12px',marginBottom:0}}><div className="row between"><span>사용자 경험 디자인</span><span className="small">11:00</span></div></div>
  </div>;
}

function ProfStart(){
  const {st,set}=useApp();
  const [acc,setAcc]=useState(5);
  const cls=profClass(Date.now());
  const start=()=>set({prof:ROSTER.map(r=>({...r,state:'none'})),profAccept:acc,profStartedAt:Date.now(),screen:'profDash'});
  return <div className="screen fade">
    <TopBar title="출석 시작" onBack={()=>set({screen:'profHome'})}/>
    <div className="scroll">
      <div className="card em"><div className="lbl">오늘의 강의</div><div className="big" style={{fontSize:17}}>인간-컴퓨터 상호작용</div>
        <div className="small muted">공대 7호관 301호 · {cls.start} ~ {cls.end}</div></div>
      <div className="card dash"><div className="lbl">출결 정책</div>
        <div className="xs muted">· 인정 시간: 출석 시작 후 설정한 분 동안</div>
        <div className="xs muted">· 인정 시간 이후 시도 → 지각</div>
        <div className="xs muted">· 오류 시 인증번호(7301) fallback</div></div>
      <div className="card"><div className="lbl">출결 인정 시간</div>
        <div className="row" style={{gap:8,flexWrap:'wrap'}}>
          {[3,5,10,15].map(m=><span key={m} className={'chip'+(acc===m?' on':'')} onClick={()=>setAcc(m)}>{m}분</span>)}
        </div></div>
    </div>
    <div className="center xs muted" style={{marginBottom:6}}>[출석 시작]을 누른 시각부터 {acc}분간 인정됩니다.</div>
    <div className="btn blue" style={{padding:16}} onClick={start}>출석 시작</div>
  </div>;
}

function evolve(arr,inAccept){
  const next=arr.map(x=>({...x}));
  let noneIdx=next.map((x,i)=>x.state==='none'?i:-1).filter(i=>i>=0);
  if(noneIdx.length===0) return next;
  let n;
  if(inAccept) n=Math.min(noneIdx.length,2+Math.floor(Math.random()*3));
  else n=(noneIdx.length>6 && Math.random()<0.6)?1:0;
  for(let c=0;c<n;c++){
    const j=Math.floor(Math.random()*noneIdx.length);
    const pick=noneIdx.splice(j,1)[0];
    next[pick].state= inAccept ? (Math.random()<0.12?'err':'att') : (Math.random()<0.25?'err':'late');
  }
  return next;
}

function ProfDash(){
  const {st,set}=useApp();
  useTick(1000);
  const ref=useRef(st.prof); ref.current=st.prof;
  const accMs=st.profAccept*60000;
  const remain=st.profStartedAt+accMs-Date.now();
  useEffect(()=>{
    const t=setInterval(()=>{
      const inAcc=Date.now()<st.profStartedAt+accMs;
      set({prof:evolve(ref.current,inAcc)});
    },SIM_TICK);
    return()=>clearInterval(t);
  },[]);
  const list=st.prof||[];
  const cnt={att:0,late:0,none:0,err:0,abs:0};
  list.forEach(s=>cnt[s.state]++);
  const sorted=[...list].sort((a,b)=>RANK[a.state]-RANK[b.state]||a.name.localeCompare(b.name,'ko'));
  return <div className="screen fade">
    <TopBar title="인간-컴퓨터 상호작용" onBack={()=>set({screen:'profHome'})}/>
    <div className="row between" style={{margin:'2px 0 6px'}}>
      <span className="small muted">출석 진행 중</span>
      <span className="b">남은시간 {remain>0?fmtMMSS(remain):'종료'}</span></div>
    <div className="card dash" style={{marginBottom:8}}><div className="row between"><span className="small muted">인증번호 (fallback)</span>
      <b style={{fontSize:20,letterSpacing:4}}>{AUTH_CODE}</b></div>
      <div className="xs muted">오류 발생 학생에게만 사용</div></div>
    <div className="sum">
      <div className="c">전체<b>{list.length}</b></div>
      <div className="c att">출석<b>{cnt.att}</b></div>
      <div className="c late">지각<b>{cnt.late}</b></div>
      <div className="c none">미처리<b>{cnt.none}</b></div>
      <div className="c err">오류<b>{cnt.err+cnt.abs}</b></div>
    </div>
    <div className="xs muted" style={{marginBottom:6}}>정렬: 오류→지각→미처리→출석 · 이름 오름차순 · 행 탭 → 변경</div>
    <div className="scroll">
      {sorted.map(s=>{const[c,l]=PST[s.state];return(
        <div key={s.id} className="stu" onClick={()=>set({editTarget:s,screen:'profEdit'})}>
          <div>{s.name}<span className="id">{s.id}</span></div>
          <div className="row" style={{gap:6}}><span className={'pill '+c}>{l}</span><span className="muted">›</span></div>
        </div>);})}
    </div>
  </div>;
}

function ProfEdit(){
  const {st,set,toast}=useApp();
  const t=st.editTarget||{};
  const [prev,setPrev]=useState(null);
  const cur=(st.prof||[]).find(x=>x.id===t.id)||t;
  function change(ns){
    setPrev(cur.state);
    set({prof:(st.prof||[]).map(x=>x.id===t.id?{...x,state:ns}:x)});
    toast(PST[ns][1]+'(으)로 변경됨');
  }
  function undo(){ set({prof:(st.prof||[]).map(x=>x.id===t.id?{...x,state:prev}:x)}); setPrev(null); toast('실행 취소'); }
  const[c,l]=PST[cur.state];
  return <div className="screen fade">
    <TopBar title="학생 상태 변경" onBack={()=>set({screen:'profDash'})}/>
    <div className="card">
      <div className="row between"><div><div className="big" style={{fontSize:17}}>{t.name}</div><div className="small muted">{t.id}</div></div>
        <span className={'pill '+c}>{l}</span></div>
      <hr/>
      <div className="row between small"><span className="muted">현재 상태</span><b>{l}</b></div>
    </div>
    <div className="small muted" style={{margin:'2px 0 8px'}}>대시보드 리스트에서 학생을 누르면 바로 이 화면이 열립니다.</div>
    {prev!=null && <div className="card dash"><div className="row between"><span className="small">상태가 변경되었습니다.</span>
      <span className="btn ghost" style={{padding:'4px 12px',fontSize:13}} onClick={undo}>실행 취소</span></div></div>}
    <div className="grow"/>
    <div className="small muted" style={{marginBottom:6}}>상태 변경</div>
    <div className="row" style={{gap:8}}>
      <div className="btn" style={{flex:1,background:'var(--green)',color:'#fff',borderColor:'var(--green)'}} onClick={()=>change('att')}>출석</div>
      <div className="btn" style={{flex:1,background:'var(--yellow)',color:'#1a1400',borderColor:'var(--yellow)'}} onClick={()=>change('late')}>지각</div>
      <div className="btn" style={{flex:1,background:'var(--red)',color:'#fff',borderColor:'var(--red)'}} onClick={()=>change('abs')}>결석</div>
    </div>
  </div>;
}

Object.assign(window,{ProfHome,ProfStart,ProfDash,ProfEdit});
