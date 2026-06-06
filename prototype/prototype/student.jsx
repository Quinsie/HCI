/* student.jsx — 학생 플로우 */

/* 사후확인 더미 주차 데이터 — 15주차, 현재 5주차 기준 */
const CUR_WEEK=5;
const _WD=[['03.04','03.06'],['03.11','03.13'],['03.18','03.20'],['03.25','03.27'],['04.01','04.03'],['04.08','04.10'],['04.15','04.17'],['04.22','04.24'],['04.29','05.01'],['05.06','05.08'],['05.13','05.15'],['05.20','05.22'],['05.27','05.29'],['06.03','06.05'],['06.10','06.12']];
const WEEKS=_WD.map(function(d,i){
  var w=i+1, s1='att', s2='att', e1={}, e2={};
  if(w>CUR_WEEK){s1='none';s2='none';}
  else if(w===CUR_WEEK){s2='none';}                 // 진행 중: 1차시 완료, 2차시 예정
  if(w===3){s2='late';e1={first:'09:01',proc:'09:03',via:'인증번호 출석',err:'PERM-03'};e2={first:'09:07',proc:'09:08',via:'인증번호 지각',err:'NET-02'};}
  if(w===4){s2='abs';}
  return {w:w, sess:[
    Object.assign({n:1,d:'2026.'+d[0],s:s1},e1),
    Object.assign({n:2,d:(s2==='none'?'예정':'2026.'+d[1]),s:s2},e2)
  ]};
});
const SLABEL={att:['att','출석'],late:['late','지각'],abs:['abs','결석'],none:['none','미처리']};

function Home(){
  const {st,set,toast}=useApp();
  useTick(1000);
  const subj=subjectById(st.preset.subject);
  const win=studentWindow(st.runtime.deadline);
  const remMs=st.runtime.deadline-Date.now();
  const p=st.preset.perms;
  const ss=st.runtime.subjectStates[subj.id];
  const slab=ss?({present:'출석 완료',late:'지각',error:'출결 오류'}[ss.state]):'미처리';
  const spill=ss?({present:'att',late:'late',error:'err'}[ss.state]):'none';
  const go=t=>set({navTab:t,screen:t==='home'?'home':t});
  return <div className="screen fade">
    <TopBar title="전자출결" right={st.preset.name}/>
    <div className="card" style={{padding:'8px 12px'}}>
      <div className="lbl">출결 준비 상태</div>
      <div className="chk">
        <b className={p.location==='allow'?'ok':'no'}>{p.location==='allow'?'✓':'✕'} 위치 권한</b>
        <b className={p.bluetooth==='allow'?'ok':'no'}>{p.bluetooth==='allow'?'✓':'✕'} 블루투스</b>
      </div>
    </div>
    <div className="card em" style={{flex:1,display:'flex',flexDirection:'column'}}>
      <div className="row between"><div className="lbl">현재 강의</div><span className={'pill '+spill}>{slab}</span></div>
      <div className="big">{subj.name}</div>
      <div className="small muted">{subj.room}</div>
      <div className="small" style={{marginTop:2}}>인정 {win.start}~{win.end} · 남은시간 <b>{remMs>0?fmtMMSS(remMs):'종료'}</b></div>
      <div className="grow"/>
      <div className="btn blue" style={{padding:16,fontSize:16}} onClick={()=>set({screen:'attend'})}>{ss?'출결 화면 열기':'출석체크'}</div>
    </div>
    <div className="small muted" style={{margin:'2px 0 6px'}}>내 수강 과목 · 수업시간 아님</div>
    {SUBJECTS.filter(s=>s.id!==subj.id).map(s=>
      <div key={s.id} className="card" style={{opacity:.5,padding:'9px 12px',marginBottom:6,cursor:'pointer'}} onClick={()=>toast('수업시간이 아닙니다')}>
        <div className="row between"><span>{s.name}</span><span className="small">비활성</span></div></div>)}
    <BottomNav tab={st.navTab} go={go}/>
  </div>;
}

function Attend(){
  const {st,set}=useApp();
  const subj=subjectById(st.preset.subject);
  const saved=st.runtime.subjectStates[subj.id];
  const blocked=st.preset.env.classroom==='out';
  const [phase,setPhase]=useState(blocked?'block':(saved?saved.state:'idle'));
  const [queue,setQueue]=useState(QUEUE_START);
  const iv=useRef(null);
  useTick(phase==='idle'?1000:99999);
  const remMs=st.runtime.deadline-Date.now();
  const win=studentWindow(st.runtime.deadline);

  useEffect(()=>{ if(saved && saved.state!==phase && phase!=='loading') setPhase(saved.state); },[saved&&saved.state,saved&&saved.method]);
  useEffect(()=>()=>clearInterval(iv.current),[]);

  function commit(runtimePatch){ set({runtime:{...st.runtime,...runtimePatch}}); }
  function press(){
    if(blocked||phase==='loading') return;
    let firstRem=st.runtime.firstRemMs;
    let rt={...st.runtime};
    if(rt.firstAttemptAt==null){ firstRem=remMs; rt.firstAttemptAt=Date.now(); rt.firstRemMs=remMs; }
    set({runtime:rt});
    setPhase('loading'); setQueue(QUEUE_START);
    let q=QUEUE_START;
    iv.current=setInterval(()=>{
      q-=1; setQueue(q>0?q:0);
      if(q<=0){ clearInterval(iv.current); finish(firstRem,rt); }
    },QUEUE_TICK);
  }
  function finish(firstRem,rt){
    const res=evaluate(st.preset.env,st.preset.perms,firstRem);
    let o;
    if(res.type==='error') o={state:'error',faults:res.faults};
    else o={state:res.type,method:'자동',at:fmtClock(new Date())};
    set({runtime:{...rt,subjectStates:{...rt.subjectStates,[subj.id]:o}}});
    setPhase(res.type==='error'?'error':res.type);
  }

  const faults=(saved&&saved.faults)||[];
  const fixList=faults.filter(f=>f.fix).map(f=>f.fix==='loc'?'위치 권한':'블루투스');
  const hasFix=fixList.length>0; const fixNames=fixList.join(' · ');
  const cstate={idle:'idle',loading:'load',present:'green',late:'yellow',error:'red',block:'block'}[phase];
  const ctitle={idle:'출석체크',loading:'출결 진행 중',present:'출석 완료',late:'지각',error:'출결 오류',block:'출석 불가'}[phase];
  const csub=phase==='late'?'처리됨':null;

  return <div className="screen fade">
    <TopBar title={subj.name.length>10?subj.name.slice(0,9)+'…':subj.name} onBack={()=>set({screen:'home'})} right="홈"/>
    <div className="attTop">
      <div className="card" style={{marginBottom:0}}>
        <div className="big" style={{fontSize:16}}>{subj.name}</div>
        <div className="small muted">인정 {win.start} ~ {win.end}</div>
      </div>
      {(phase==='idle'||phase==='loading') &&
        <div className="center" style={{marginTop:2}}>
          <div className="xs muted">남은 출석 인정 시간</div>
          <div style={{fontSize:22,fontWeight:800}}>{remMs>0?fmtMMSS(remMs):'지남'}</div>
        </div>}
      {(phase==='present'||phase==='late') &&
        <div className="center" style={{marginTop:2}}>
          <div className="xs muted">처리 시각</div>
          <div style={{fontSize:22,fontWeight:800}}>{saved&&saved.at}</div>
        </div>}
      {phase==='error' &&
        <div className="card warn" style={{marginTop:2,marginBottom:0,padding:'7px 10px'}}>
          <div className="xs muted" style={{marginBottom:2}}>감지된 오류 {faults.length}건 · 최초 시도 {st.runtime.firstAttemptAt?fmtClock(new Date(st.runtime.firstAttemptAt)):'—'}</div>
          {faults.map(f=><div key={f.code} className="xs"><b>{f.code}</b> · {f.msg}</div>)}
          {hasFix && <div className="xs" style={{marginTop:3}}>→ 설정에서 <b>{fixNames}</b> 켠 뒤 재시도</div>}
        </div>}
      {phase==='block' && <div className="center small muted" style={{marginTop:8}}>강의실 밖에서는 출석할 수 없습니다.</div>}
    </div>
    <div className="circleZone">
      <Circle state={cstate} title={ctitle} sub={csub} onTap={phase==='idle'?press:null}/>
    </div>
    <div className="attBottom">
      {phase==='idle' && <div className="small center muted">강의실 안에서 출석체크 버튼을 눌러주세요.</div>}
      {phase==='loading' && <div className="center"><div className="small b">대기 순번 {queue}번</div><div className="xs muted">처리 결과가 도착하면 표시됩니다</div></div>}
      {phase==='present' && <div className="small center muted">{saved&&saved.method==='인증번호'?'인증번호 출석':'자동 출석'} 처리되었습니다.</div>}
      {phase==='late' && <div className="small center muted">인정시간 이후 처리되어 {saved&&saved.method==='인증번호'?'인증번호 ':''}지각 기록되었습니다.</div>}
      {phase==='error' && <>
        {hasFix && <div className="btn ghost" style={{width:'100%',padding:9,fontSize:13}} onClick={()=>set({screen:'settings',navTab:'settings'})}>설정으로 이동 →</div>}
        <div className="row" style={{gap:8,width:'100%'}}>
          <div className="btn ghost" style={{flex:1,padding:9,fontSize:13}} onClick={press}>재시도</div>
          <div className="btn pri" style={{flex:1,padding:9,fontSize:13}} onClick={()=>set({screen:'auth'})}>인증번호 입력</div>
        </div>
      </>}
    </div>
  </div>;
}

function Auth(){
  const {st,set,toast}=useApp();
  const subj=subjectById(st.preset.subject);
  const [v,setV]=useState('');
  const tap=k=>{ if(k==='del') setV(v.slice(0,-1)); else if(k==='ok') submit(); else if(v.length<4) setV(v+k); };
  function submit(){
    if(v!==AUTH_CODE){ toast('인증번호가 올바르지 않습니다'); setV(''); return; }
    const firstRem=st.runtime.firstRemMs||0;
    const type=firstRem>0?'present':'late';
    const o={state:type,method:'인증번호',at:fmtClock(new Date())};
    set({runtime:{...st.runtime,subjectStates:{...st.runtime.subjectStates,[subj.id]:o}},screen:'attend'});
    toast(type==='present'?'출석 처리되었습니다':'지각 처리되었습니다');
  }
  const keys=['1','2','3','4','5','6','7','8','9','del','0','ok'];
  return <div className="screen fade">
    <TopBar title="인증번호 출결" onBack={()=>set({screen:'attend'})}/>
    <div className="card warn"><div className="row between small"><span className="muted">최초 시도 시각</span><b>{st.runtime.firstAttemptAt?fmtClock(new Date(st.runtime.firstAttemptAt)):'—'}</b></div>
      <div className="xs">이 시각 기준으로 출석/지각 자동 판정</div></div>
    <div className="grow"/>
    <div className="center small">교수자가 칠판에 적은 <b>4자리 인증번호</b>를 입력하세요.</div>
    <div className="pin">{[0,1,2,3].map(i=><div key={i} className={'d'+(v[i]?'':' e')}>{v[i]||'_'}</div>)}</div>
    <div className="grow"/>
    <div className="keypad">{keys.map(k=>
      <div key={k} className={'k'+(k==='ok'?' act':'')} onClick={()=>tap(k)}>{k==='del'?'⌫':k==='ok'?'확인':k}</div>)}</div>
  </div>;
}

function Settings(){
  const {st,set}=useApp();
  const p=st.preset.perms;
  const setPerm=(k,val)=>set({preset:{...st.preset,perms:{...p,[k]:val}}});
  const go=t=>set({navTab:t,screen:t==='home'?'home':t});
  return <div className="screen fade">
    <TopBar title="설정"/>
    <div className="scroll">
      <div className="card warn"><div className="small">출결 오류가 났다면 아래 권한을 켜고 다시 시도하세요.</div></div>
      <div className="card">
        <div className="row between" style={{marginBottom:10}}><span>위치 권한</span><Seg value={p.location} options={[{v:'deny',l:'OFF'},{v:'allow',l:'ON'}]} onChange={v=>setPerm('location',v)}/></div>
        <div className="row between"><span>블루투스</span><Seg value={p.bluetooth} options={[{v:'deny',l:'OFF'},{v:'allow',l:'ON'}]} onChange={v=>setPerm('bluetooth',v)}/></div>
      </div>
      <div className="xs muted">※ 강의실 위치·네트워크·서버는 운영자만 설정(여기 없음).</div>
    </div>
    <BottomNav tab={st.navTab} go={go}/>
  </div>;
}

function History(){
  const {st,set}=useApp();
  const go=t=>set({navTab:t,screen:t==='home'?'home':t});
  return <div className="screen fade">
    <TopBar title="출석 현황"/>
    <div className="scroll">
      <div className="card warn"><div className="lbl">⚠ 출결 유의사항</div>
        <div className="small">총 수업시수의 <b>1/4 이상 결석 시 F</b>.</div>
        <div className="small">전체 = 총 차시(15주 기준).</div></div>
      {SUBJECTS.map(s=>{const h=s.hist;return(
        <div key={s.id} className="card" style={{cursor:'pointer'}} onClick={()=>set({histSubject:s.id,screen:'weeks'})}>
          <div className="row between"><div className="big" style={{fontSize:16}}>{s.name}</div><span className="muted">›</span></div>
          <hr/>
          <div className="row" style={{gap:14,fontSize:12,flexWrap:'wrap'}}>
            <span><span className="pill none">전체</span> <b>{s.total}</b></span>
            <span><span className="pill att">출석</span> <b>{h.att}</b></span>
            <span><span className="pill late">지각</span> <b>{h.late}</b></span>
            <span><span className="pill abs">결석</span> <b>{h.abs}</b></span>
          </div>
          <hr/>
          <div className="row between"><span className="small muted">현재 상태</span><span className={'pill '+(h.risk==='주의'?'warn':'att')}>{h.risk}</span></div>
        </div>);})}
    </div>
    <BottomNav tab={st.navTab} go={go}/>
  </div>;
}

function Weeks(){
  const {st,set}=useApp();
  const subj=subjectById(st.histSubject);
  const [open,setOpen]=useState(CUR_WEEK);
  return <div className="screen fade">
    <TopBar title={subj.name.length>11?subj.name.slice(0,10)+'…':subj.name} onBack={()=>set({screen:'history'})}/>
    <div className="row" style={{gap:6,flexWrap:'wrap',marginBottom:8}}>
      <span className="pill att">출석</span><span className="pill late">지각</span><span className="pill abs">결석</span><span className="pill none">미처리</span></div>
    <div className="scroll">
      {WEEKS.map(w=>{const op=open===w.w;const sess=subj.per===1?[w.sess[0]]:w.sess;return(<div key={w.w}>
        <div className="wk" onClick={()=>setOpen(op?0:w.w)}>
          <div className="row"><span className="muted">{op?'▾':'▸'}</span> <b>{w.w}주차</b></div>
          <span className="small muted">{(function(){var c={att:0,late:0,abs:0,none:0};sess.forEach(function(s){c[s.s]++;});return (c.att+c.late+c.abs===0)?'미처리/예정':'출석 '+c.att+' · 지각 '+c.late+' · 결석 '+c.abs;})()}</span>
        </div>
        {op && <div onClick={()=>set({detail:{w:w.w,sess:sess},screen:'detail'})} style={{border:'1px solid #e2e2de',borderTop:'none',borderRadius:'0 0 10px 10px',padding:'4px 10px 8px',margin:'-6px 0 6px',background:'#fafafa',cursor:'pointer'}}>
          {sess.map(se=>{const[c,l]=SLABEL[se.s];return(
            <div key={se.n} className="row between" style={{padding:'7px 0'}}>
              <span className="small">{se.n}차시 · {se.d}</span><span className={'pill '+c}>{l}</span></div>);})}
          <div className="xs muted center" style={{marginTop:2}}>차시 상세 보기 ›</div>
        </div>}
      </div>);})}
    </div>
  </div>;
}

function Detail(){
  const {st,set}=useApp();
  const d=st.detail||{sess:[]};
  return <div className="screen fade">
    <TopBar title={(d.w?d.w+'주차 ':'')+'출석 상세'} onBack={()=>set({screen:'weeks'})}/>
    <div className="scroll">
      {(d.sess||[]).map(se=>{const[c,l]=SLABEL[se.s];return(
        <div key={se.n} className="card">
          <div className="row between"><div className="big" style={{fontSize:16}}>{se.n}차시</div><span className={'pill '+c}>{l}</span></div>
          <div className="small muted">{se.d}</div>
          <hr/>
          <div className="row between small" style={{marginBottom:4}}><span className="muted">처리 시각</span><b>{se.proc||'—'}</b></div>
          <div className="row between small" style={{marginBottom:4}}><span className="muted">최초 시도 시각</span><b>{se.first||'—'}</b></div>
          <div className="row between small" style={{marginBottom:4}}><span className="muted">처리 방식</span><b>{se.via||(se.s==='none'?'미실시':'자동 처리')}</b></div>
          <div className="row between small"><span className="muted">오류 발생</span><b>{se.err?'있음 · '+se.err:'없음'}</b></div>
        </div>);})}
      <div className="card dash"><div className="small muted">처리 시각·방식·오류 여부는 정정 요청의 근거 자료로 사용됩니다.</div></div>
    </div>
  </div>;
}

Object.assign(window,{Home,Attend,Auth,Settings,History,Weeks,Detail});
