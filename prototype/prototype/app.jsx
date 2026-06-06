/* app.jsx — 루트 · 라우터 */
function Root(){
  const store=useStore();
  const {st}=store;
  const SCREENS={
    splash:Splash, login:Login, debug1:Debug1, debug2:Debug2,
    home:Home, attend:Attend, auth:Auth, settings:Settings,
    history:History, weeks:Weeks, detail:Detail,
    profHome:ProfHome, profStart:ProfStart, profDash:ProfDash, profEdit:ProfEdit,
  };
  const Screen=SCREENS[st.screen]||Splash;
  return <Ctx.Provider value={store}>
    <StatusBar/>
    <div className="app"><Screen/></div>
    <Toast/>
  </Ctx.Provider>;
}
ReactDOM.createRoot(document.getElementById('device')).render(<Root/>);
