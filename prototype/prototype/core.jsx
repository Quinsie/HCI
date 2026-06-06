/* core.jsx — 상태 스토어 · 로직 · 공용 컴포넌트 */
const {useState,useEffect,useRef,useReducer,useContext,createContext,useCallback}=React;

/* ===== 상수 ===== */
const ACCEPT_MIN=5;              // 인정 시간 고정(분)
const QUEUE_START=7;             // 대기 큐 시작 번호
const QUEUE_TICK=470;            // 큐 1감소 간격(ms)
const SPLASH_MS=3000;            // 스플래시 정지(ms)
const AUTH_CODE='7301';          // 고정 인증번호
const SIM_TICK=1100;             // 교수 대시보드 시뮬 갱신(ms)
const STUDENT_ACC={id:'202600001',pw:'1q2w3e'};
const PROF_ACC={id:'50001',pw:'1a2s3d'};

const SUBJECTS=[
  {id:'hci',name:'인간-컴퓨터 상호작용',room:'공대 7호관 301호',per:2,total:30, hist:{att:7,late:1,abs:1,risk:'주의'}},
  {id:'ux', name:'사용자 경험 디자인',  room:'공대 6호관 210호',per:1,total:15, hist:{att:9,late:0,abs:0,risk:'정상'}},
  {id:'dr', name:'디자인 리서치',        room:'공대 7호관 415호',per:1,total:15, hist:{att:7,late:2,abs:0,risk:'정상'}},
];
const subjectById=(id)=>SUBJECTS.find(s=>s.id===id)||SUBJECTS[0];

const ROSTER=[
 '김민준','이서연','정우진','최예은','강하윤','조현우','윤지우','임도윤','한서준','오지민',
 '서준영','신유나','권태현','황민서','송재윤','안소율','류하은','배성민','전지안','홍시우',
 '고은채','문준호','양다은','백지원','허윤서','남기훈','심예진','노건우','하지율','곽도현',
 '성민재','박지호','차예린','주한결','우지호','구나윤','마동현','진서아','표은지','명재훈'
].map((n,i)=>({id:'2026'+String(i+1).padStart(5,'0'),name:n}));

const DEFAULT_PRESET={
  persona:'student', name:'홍길동', subject:'hci', acceptMin:ACCEPT_MIN, remainingSec:150,
  perms:{location:'allow',bluetooth:'allow'},
  env:{classroom:'in',network:'ok',server:'ok'},
};

/* ===== 시간/판정 헬퍼 ===== */
function pad(n){return String(n).padStart(2,'0');}
function fmtClock(d){return pad(d.getHours())+':'+pad(d.getMinutes());}
function fmtMMSS(ms){if(ms<0)ms=0;var s=Math.round(ms/1000);return pad(Math.floor(s/60))+':'+pad(s%60);}
function profClass(now){var s=new Date(now);s.setMinutes(0,0,0);var e=new Date(s.getTime()+90*60000);return{start:fmtClock(s),end:fmtClock(e)};}
function studentWindow(deadline){return{start:fmtClock(new Date(deadline-ACCEPT_MIN*60000)),end:fmtClock(new Date(deadline))};}

// 출결 버튼 판정 (명세서 §6) — 강의실 밖=차단, 그 외엔 감지된 모든 결함을 수집
function evaluate(env,perms,remainingMs){
  if(env.classroom==='out') return {type:'block'};
  var faults=[];
  if(perms.location==='deny') faults.push({code:'PERM-03',msg:'위치 권한이 꺼져 있습니다.',fix:'loc'});
  if(perms.bluetooth==='deny') faults.push({code:'BT-05',msg:'블루투스가 꺼져 있습니다.',fix:'bt'});
  if(env.network==='err') faults.push({code:'NET-02',msg:'네트워크 연결에 실패했습니다.'});
  if(env.server==='err') faults.push({code:'SRV-04',msg:'서버가 응답하지 않습니다.'});
  if(faults.length) return {type:'error',faults:faults};
  return remainingMs>0?{type:'present'}:{type:'late'};
}

/* ===== 영속 저장 ===== */
const KEY='eatt_proto_v1';
function loadP(){try{return JSON.parse(localStorage.getItem(KEY))}catch(e){return null}}
function saveP(o){try{localStorage.setItem(KEY,JSON.stringify(o))}catch(e){}}

/* ===== 스토어 ===== */
const Ctx=createContext(null);
const useApp=()=>useContext(Ctx);

function freshRuntime(preset){return {firstAttemptAt:null,subjectStates:{},deadline:Date.now()+preset.remainingSec*1000};}

function useStore(){
  const p=loadP();
  const preset0 = p?p.preset:DEFAULT_PRESET;
  let runtime0 = p?p.runtime:freshRuntime(preset0);
  // 아직 출결을 시도하지 않았는데 deadline이 과거면(재로드로 시간 경과) 갱신
  if(runtime0.firstAttemptAt==null && runtime0.deadline<Date.now())
    runtime0={...runtime0,deadline:Date.now()+preset0.remainingSec*1000};
  const init={
    screen:'splash', navTab:'home', logoTaps:0, toast:'',
    preset: preset0,
    runtime: runtime0,
    draft:null,                 // 디버그 작성중 프리셋
    profAccept:5, profStartedAt:null, // 교수 세션
    editTarget:null,
  };
  const [st,dispatch]=useReducer((s,a)=>({...s,...a}),init);
  useEffect(()=>{saveP({preset:st.preset,runtime:st.runtime});},[st.preset,st.runtime]);
  const set=useCallback(p=>dispatch(p),[]);
  const toast=useCallback((m)=>{dispatch({toast:m});setTimeout(()=>dispatch({toast:''}),1600);},[]);
  // 프리셋 적용(핸드오프)
  const applyPreset=useCallback((preset)=>{dispatch({preset,runtime:freshRuntime(preset),draft:null,screen:'splash',logoTaps:0,navTab:'home'});},[]);
  return {st,set,toast,applyPreset};
}

/* 주기적 리렌더(카운트다운/시뮬용) */
function useTick(ms){const[,f]=useState(0);useEffect(()=>{const t=setInterval(()=>f(x=>x+1),ms);return()=>clearInterval(t);},[ms]);}

/* ===== 공용 컴포넌트 ===== */
function StatusBar(){
  useTick(1000);
  const d=new Date();
  return <div className="statusbar"><span>{fmtClock(d)}</span><span>● ● ●</span></div>;
}

function TopBar({title,onBack,right}){
  const {st,set}=useApp();
  const taps=useRef(0), tmr=useRef(null);
  const hit=()=>{ taps.current++; clearTimeout(tmr.current); tmr.current=setTimeout(()=>{taps.current=0;},1200);
    if(taps.current>=5){ taps.current=0; set({draft:JSON.parse(JSON.stringify(st.preset)),screen:'debug1'}); } };
  return <div className="topbar">
    {onBack?<div className="back" onClick={onBack}>‹</div>:null}
    <div className="t" onClick={hit}>{title}</div>
    {right?<div className="r">{right}</div>:null}
  </div>;
}

// 중앙 원 — 항상 같은 위치/같은 크기. 색·텍스트만 변함.
function Circle({state,title,sub,onTap}){
  return <div className={'circle '+state+(onTap?' tap':'')} onClick={onTap||undefined}>
    <div className="ct" style={state==='load'?{fontSize:15}:null}>{title}</div>
    {sub?<div className="cs">{sub}</div>:null}
  </div>;
}

function BottomNav({tab,go}){
  const items=[['home','홈'],['history','현황'],['settings','설정']];
  return <div className="nav">
    {items.map(([k,l])=><div key={k} className={tab===k?'on':''} onClick={()=>go(k)}>{l}</div>)}
  </div>;
}

function Seg({value,options,onChange}){
  return <div className="seg">{options.map(o=>
    <div key={o.v} className={value===o.v?'on':''} onClick={()=>onChange(o.v)}>{o.l}</div>)}</div>;
}

function Toast(){const{st}=useApp();return <div className={'toast'+(st.toast?' show':'')}>{st.toast}</div>;}

Object.assign(window,{
  Ctx,useApp,useStore,useTick,
  StatusBar,TopBar,Circle,BottomNav,Seg,Toast,
  profClass,studentWindow,fmtMMSS,fmtClock,evaluate,pad,
  ROSTER,SUBJECTS,subjectById,STUDENT_ACC,PROF_ACC,AUTH_CODE,
  ACCEPT_MIN,QUEUE_START,QUEUE_TICK,SPLASH_MS,SIM_TICK,DEFAULT_PRESET,
});
