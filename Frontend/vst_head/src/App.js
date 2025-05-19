import React from "react";
import { BrowserRouter as Router, Routes, Route, useLocation } from "react-router-dom";
import Login from "./pages/Login";
import Customer from "./pages/customer";
import Staff from "./pages/staff";
import EditReq from "./pages/editReq";
import UnavaReq from "./pages/unavaReq";
import CreateCard from "./pages/createcard";
import Service from "./pages/service";
import Sidebar from "./components/Sidebar";
import "./App.css";
import ShowCard from "./pages/showcard";
import Essentials from "./pages/essentials";

const Layout = ({ children }) => {
  const location = useLocation();
  const showSidebar = location.pathname !== "/head/"; // Hide sidebar on Login page

  return (
    <div className="app-container">
      {showSidebar && <Sidebar />}
      <div className="content">{children}</div>
    </div>
  );
};

const App = () => {
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/head" element={<Login />} />
          <Route path="/head/customer" element={<Customer />} />
          <Route path="/head/staff" element={<Staff />} />
          <Route path="/head/editreq" element={<EditReq />} />
          <Route path="/head/unavareq" element={<UnavaReq />} />
          <Route path="/head/createcard" element={<CreateCard />} />
          <Route path="/head/showcard" element={<ShowCard/>} />
          <Route path="/head/service" element={<Service/>} />
          <Route path="/head/essentials" element={<Essentials/>} />
        </Routes>
      </Layout>
    </Router>
  );
};

export default App;
