import '../styles/createcard.css';
import CreateCardimg from '../assets/createcard.jpg';
import axios from 'axios';
import Cookies from 'js-cookie';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const CreateCard=()=>{

    const refreshToken = Cookies.get('refresh_token');
    const [createUser, setCreateUser] = useState({});
    const [createServiceCustomerId, setcreateServiceCustomerId] = useState("");
    const [customerPhone, setCustomerPhone] = useState("");
    const [model, setModel] = useState("");
    const [cid, setCid] = useState("");
    const [doi, setDoi] = useState("");
    const [wsd, setWsd] = useState("");
    const [wed, setWed] = useState("");
    const [acmsd, setAcmsd] = useState("");
    const [acmed, setAcmed] = useState("");
    const [csd, setCsd] = useState("");
    const [ced, setCed] = useState("");

     /* ------------------------------------------------------------------ */
    /* ───────────────────────────  ROUTING  ──────────────────────────── */
    /* ------------------------------------------------------------------ */
    const navigate = useNavigate();

    /** Redirect unauthenticated users to /head/ immediately. */
    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);



    // Refresh Token Function
    const refresh_token = async () => {
        try {
            const res = await axios.post("http://157.173.220.208/log/token/refresh/", { 'refresh': refreshToken }, { headers: { "Content-Type": "application/json" } });
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            return null;
        }
    };

    const post_card = async (accessToken) => {
        
        if(model.trim() === "" || doi.trim() === ""){
            window.alert("Please Fill Required fields !");
            return;
        }
        const confirmAction = window.confirm("Are you sure you want to create card?");
        if (!confirmAction) return;
        const data = {
            model: model,
            customer_code: parseInt(cid),
            customer_name: "Placeholder",
            region: "rajapalayam",
            address: "Placeholder",
            date_of_installation: doi,
            warranty_start_date: wsd,
            warranty_end_date: wed
        };

        if (acmsd.trim() !== "") data.acm_start_date = acmsd;
        if (acmed.trim() !== "") data.acm_end_date = acmed;
        if (csd.trim() !== "") data.contract_start_date = csd;
        if (ced.trim() !== "") data.contract_end_date = ced;
        try {
            const response = await axios.post(`http://157.173.220.208/api/headcreatecard/`,data ,{
                headers: { 
                    Authorization: `Bearer ${accessToken}`,
                    'Content-Type': 'application/json'
                }
            });
            if (response.data) {
                window.alert("Card Created Successfully");
                window.location.reload();
            }
        } catch (error) {
            console.error("Error fetching customer:", error);
        }
    };

    const create_card = async () => {
        const accessToken = await refresh_token();
        if (accessToken) await post_card(accessToken);
    };

    const getUserByPhone = async (phone) => {
        const accessToken = await refresh_token();
        if (!accessToken && phone.length()!==10) return;
        try {
            const response = await axios.get(`http://157.173.220.208/utils/getuserbyphone/${phone}`, { headers: { Authorization: `Bearer ${accessToken}` } });
            setCreateUser(response.data);
            setCid(response.data.id);
            setcreateServiceCustomerId(response.data.id);
        } catch (error) {
            setCreateUser({});
            console.error("Error fetching customer by phone:", error);
        }
    };

    return(
        <div className="createcard-cont">
            <div className='createcard-l'>
                <div className='createcard-card'>
                    <p className='createcard-title'>Create Card</p>
                    <div className='createcard-inputs'>
                    <div className='createcard-input-cont'>
                        <p>Model Name</p>
                        <input type="text" placeholder="Model Name" className="createcard-card-input" onChange={(e)=>setModel(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>Customer : {createUser.name?createUser.name + " ( " + createUser.id + " )" : "Not Found"}</p>
                        <input type="text" placeholder="Customer Phone" className="createcard-card-input" onChange={(e)=>{getUserByPhone(e.target.value)}}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>Date Of Installation</p>
                        <input type="date" placeholder="Date Of Installation" className="createcard-card-input" onChange={(e)=>setDoi(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>Warranty Start Date</p>
                        <input type="date" placeholder="Warranty Start Date" className="createcard-card-input" onChange={(e)=>setWsd(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>Warranty End Date</p>
                        <input type="date" placeholder="Warranty End Date" className="createcard-card-input" onChange={(e)=>setWed(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>ACM Start Date</p>
                        <input type="date" placeholder="ACM Start Date" className="createcard-card-input" onChange={(e)=>setAcmsd(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>ACM End Date</p>
                        <input type="date" placeholder="ACM End Date" className="createcard-card-input" onChange={(e)=>setAcmed(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>Contract Start Date</p>
                        <input type="date" placeholder="Contract Start Date" className="createcard-card-input" onChange={(e)=>setCsd(e.target.value)}/>
                    </div>
                    <div className='createcard-input-cont'>
                        <p>Contract End Date</p>
                        <input type="date" placeholder="Contract End Date" className="createcard-card-input" onChange={(e)=>setCed(e.target.value)}/>
                    </div>
                    </div>
                    <button className='createcard-card-button' onClick={()=>create_card()}>Create Card</button>
                </div>
            </div>
            <div className='createcard-r'>
                <div className='createcard-img-cont'>
                    <img src={CreateCardimg} alt='illustration'/>
                    <p>When Customer Purchase a product from the VST Maarketing Create a Card For There Customer ID To Track the status of the service and allow user to book the service on that card.</p>
                </div>
            </div>
        </div>
    )
}

export default CreateCard;