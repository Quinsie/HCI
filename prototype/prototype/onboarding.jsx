/* onboarding.jsx — 스플래시 · 로그인 · 디버그 프리셋(OP1/OP2) */

function Splash(){
  const {st,set}=useApp();
  useEffect(()=>{const t=setTimeout(()=>set({screen:'login'}),SPLASH_MS);return()=>clearTimeout(t);},[]);
  const tap=()=>{
    const n=st.logoTaps+1;
    if(n>=5) set({logoTaps:0,draft:JSON.parse(JSON.stringify(st.preset)),screen:'debug1'});
    else set({logoTaps:n});
  };
  return <div className="screen fade" style={{alignItems:'center',justifyContent:'center'}}>
    <div className="grow"/>
    <div onClick={tap} style={{width:104,height:104,border:'2px solid #111',borderRadius:28,display:'flex',alignItems:'center',justifyContent:'center',position:'relative',cursor:'pointer'}}>
      <span style={{fontSize:13,color:'#888'}}>로고</span>
      {st.logoTaps>0 && <span style={{position:'absolute',right:-12,bottom:-12,border:'1px solid #111',background:'#fff',fontSize:11,padding:'1px 6px',borderRadius:8}}>{st.logoTaps}/5</span>}
    </div>
    <div style={{textAlign:'center',marginTop:16}}>
      <div style={{fontSize:22,fontWeight:800}}>전자출결</div>
      <div className="small muted">Electronic Attendance</div>
    </div>
    <div className="grow"/>
    <div className="hint">로고 5번 탭 → 디버그 · 3초 후 로그인</div>
  </div>;
}

function Login(){
  const {st,set}=useApp();
  const acc=st.preset.persona==='prof'?PROF_ACC:STUDENT_ACC;
  const [id,setId]=useState(acc.id);
  const [pw,setPw]=useState(acc.pw);
  const go=()=>set({screen:st.preset.persona==='prof'?'profHome':'home',navTab:'home'});
  return <div className="screen fade">
    <TopBar title="로그인"/>
    <div className="grow"/>
    <div style={{textAlign:'center'}}>
      <div style={{width:66,height:66,border:'1.5px solid #111',borderRadius:18,margin:'0 auto 10px',display:'flex',alignItems:'center',justifyContent:'center'}}><span className="small muted">로고</span></div>
      <div style={{fontSize:18,fontWeight:800}}>전자출결</div>
    </div>
    <div style={{flex:1.3}}/>
    <div className="field"><div className="lbl">학번 / 사번</div>
      <input value={id} onChange={e=>setId(e.target.value)} style={{border:'none',outline:'none',width:'100%',fontSize:15}}/></div>
    <div className="field"><div className="lbl">비밀번호</div>
      <input value={pw} type="password" onChange={e=>setPw(e.target.value)} style={{border:'none',outline:'none',width:'100%',fontSize:15}}/></div>
    <div className="btn pri" onClick={go}>로그인</div>
    <div className="center xs muted" style={{marginTop:8}}>프리셋 계정 자동 입력 · {st.preset.persona==='prof'?'교수':'학생'}</div>
  </div>;
}

function Debug1(){
  const {st,set,applyPreset}=useApp();
  const d=st.draft||DEFAULT_PRESET;
  const upd=p=>set({draft:{...d,...p}});
  const stuAcc=STUDENT_ACC, profAcc=PROF_ACC;
  const isStu=d.persona!=='prof';
  const remLbl=d.remainingSec<=0?'0:00 · 경과(지각)':fmtMMSS(d.remainingSec*1000);
  return <div className="screen fade">
    <TopBar title="디버그 · 시나리오" onBack={()=>set({screen:'splash'})} right={isStu?'1/2':'1/1'}/>
    <div className="scroll">
      <div className="card"><div className="lbl">피험자 페르소나</div>
        <Seg value={d.persona} options={[{v:'student',l:'학생'},{v:'prof',l:'교수'}]} onChange={v=>upd({persona:v})}/>
      </div>
      <div className="card">
        <div className="lbl">이름 (직접 입력)</div>
        <input value={d.name} onChange={e=>upd({name:e.target.value})} placeholder="이름 입력…" style={{border:'1px solid #d8d8d4',borderRadius:10,padding:'8px 10px',width:'100%',fontSize:14,marginBottom:8,outline:'none'}}/>
        <div className="row between small"><span className="muted">{isStu?'학번':'사번'}</span><b>{isStu?stuAcc.id:profAcc.id}</b></div>
        <div className="row between small"><span className="muted">비밀번호</span><b>{isStu?stuAcc.pw:profAcc.pw}</b></div>
        <div className="xs muted" style={{marginTop:4}}>계정·비번 고정</div>
      </div>
      {isStu ? <>
        <div className="card"><div className="lbl">강의 · 시간</div>
          <div className="row" style={{flexWrap:'wrap',gap:6,marginBottom:8}}>
            {SUBJECTS.map(s=><span key={s.id} className={'chip'+(d.subject===s.id?' on':'')} onClick={()=>upd({subject:s.id})}>{s.name.length>8?s.name.slice(0,7)+'…':s.name}</span>)}
          </div>
          <div className="row between small"><span className="muted">인정 시간</span><b>5분 · 고정</b></div>
          <hr/>
          <div className="row between"><span className="small muted">남은 인정 시간</span><b>{remLbl}</b></div>
          <div className="row" style={{marginTop:8,gap:8}}>
            <div className="btn ghost" style={{flex:1,padding:10}} onClick={()=>upd({remainingSec:Math.max(0,d.remainingSec-15)})}>− 15초</div>
            <div className="btn ghost" style={{flex:1,padding:10}} onClick={()=>upd({remainingSec:Math.min(300,d.remainingSec+15)})}>+ 15초</div>
          </div>
          <div className="xs muted" style={{marginTop:6}}>0:00 = 경과 → 지각 상황으로 시작</div>
        </div>
      </> : <div className="card dash"><div className="lbl">교수는 환경 분기 없음</div>
        <div className="small">권한·환경 설정 없이 바로 핸드오프. 인정시간 설정·출석 시작은 앱 내 P01에서.</div></div>}
    </div>
    <div className="btn ghost" style={{marginBottom:8,padding:10,fontSize:13}} onClick={()=>{try{localStorage.removeItem('eatt_proto_v1');}catch(e){} location.reload();}}>전체 초기화 · 처음부터</div>
    {isStu
      ? <div className="btn pri" onClick={()=>set({screen:'debug2'})}>다음 · 기기 상태 →</div>
      : <div className="btn pri" onClick={()=>applyPreset({...d,persona:'prof'})}>적용 &amp; 핸드오프</div>}
  </div>;
}

function Debug2(){
  const {st,set,applyPreset}=useApp();
  const d=st.draft||DEFAULT_PRESET;
  const upd=p=>set({draft:{...d,...p}});
  const updP=p=>upd({perms:{...d.perms,...p}});
  const updE=p=>upd({env:{...d.env,...p}});
  const r=evaluate(d.env,d.perms,d.remainingSec>0?1:-1);
  const rTxt = r.type==='error' ? r.faults.map(f=>f.code).join(', ')+' 오류'
            : {present:'정상 출석',late:'지각',block:'차단(강의실 밖)'}[r.type];
  return <div className="screen fade">
    <TopBar title="디버그 · 기기 상태" onBack={()=>set({screen:'debug1'})} right="2/2"/>
    <div className="scroll">
      <div className="card"><div className="lbl">권한 초기값 · 피험자 변경 가능</div>
        <div className="row between" style={{marginBottom:8}}><span>위치</span><Seg value={d.perms.location} options={[{v:'allow',l:'허용'},{v:'deny',l:'거부'}]} onChange={v=>updP({location:v})}/></div>
        <div className="row between"><span>블루투스</span><Seg value={d.perms.bluetooth} options={[{v:'allow',l:'허용'},{v:'deny',l:'거부'}]} onChange={v=>updP({bluetooth:v})}/></div>
        <div className="xs muted" style={{marginTop:6}}>거부로 줘도 피험자가 설정에서 켜면 정상</div>
      </div>
      <div className="card"><div className="lbl">환경 상태 · 피험자 변경 불가</div>
        <div className="row between" style={{marginBottom:8}}><span>강의실 위치</span><Seg value={d.env.classroom} options={[{v:'in',l:'내'},{v:'out',l:'밖'}]} onChange={v=>updE({classroom:v})}/></div>
        <div className="row between" style={{marginBottom:8}}><span>네트워크</span><Seg value={d.env.network} options={[{v:'ok',l:'정상'},{v:'err',l:'오류'}]} onChange={v=>updE({network:v})}/></div>
        <div className="row between"><span>서버</span><Seg value={d.env.server} options={[{v:'ok',l:'정상'},{v:'err',l:'오류'}]} onChange={v=>updE({server:v})}/></div>
      </div>
      <div className="card dash"><div className="lbl">결과 미리보기</div><div className="small">현재 설정 → <b>{rTxt}</b></div></div>
    </div>
    <div className="center xs muted" style={{marginBottom:6}}>적용 시 기기에 저장 · 재시작해도 고정</div>
    <div className="btn pri" onClick={()=>applyPreset(d)}>적용 &amp; 피험자에게 핸드오프</div>
  </div>;
}

Object.assign(window,{Splash,Login,Debug1,Debug2});
