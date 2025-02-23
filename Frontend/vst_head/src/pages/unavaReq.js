import React, { useState, useEffect } from 'react';
import '../styles/unavareq.css';
import axios from 'axios';
import Cookies from 'js-cookie';

const UnavaReq = () => {
    const [reqData, setreqData] = useState(null);
    const [AllreqData, setAllreqData] = useState([]);
    const refreshToken = Cookies.get('refresh_token');

    const refresh_token = async () => {
        try {
            const res = await axios.post("http://127.0.0.1:8000/log/token/refresh/", 
                { 'refresh': refreshToken }, 
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            return null;
        }
    };

    const fetch_req = async (accessToken) => {
        try {
            const response = await axios.get("http://127.0.0.1:8000/utils/headviewunavareq/", {
                headers: { Authorization: `Bearer ${accessToken}` }
            });
            if (response.data) {
                setAllreqData(response.data);
            }
        } catch (error) {
            console.error("Error fetching data:", error);
            setAllreqData([]);
        }
    };

    const fetch_req_in = async () => {
        const RT = await refresh_token();
        if (RT) await fetch_req(RT);
    };

    useEffect(() => {
        fetch_req_in();
    }, []);

    const accept_req = async (req_id) => {
        const confirmAction = window.confirm("Are you sure you want to APPROVE AND RESSIGN this request?");
        if (!confirmAction) return;

        const AT = await refresh_token();
        try {
            const response = await axios.post(`http://127.0.0.1:8000/utils/reassingstaff/${req_id}`, {},{
                headers: { Authorization: `Bearer ${AT}` }
            });
            if (response.data) {
                console.log(response.data);
                setreqData(null);
                window.location.reload();
            }
        } catch (error) {
            console.error("Error approving request:", error);
        }
    };

    const reject_req = async (req_id) => {
        const confirmAction = window.confirm("Are you sure you want to REJECT this request?");
        if (!confirmAction) return;

        const AT = await refresh_token();
        try {
            const response = await axios.get(`http://127.0.0.1:8000/utils/headrejectunavareq/${req_id}`, {
                headers: { Authorization: `Bearer ${AT}` }
            });
            if (response.data) {
                console.log(response.data);
                setreqData(null);
                window.location.reload();
            }
        } catch (error) {
            console.error("Error approving request:", error);
        }
    };

    return (
        <div className="unavareq-cont">
            <div className="unavareq-l">
                <div className="unavareq-table">
                    <table className="unavareq-list">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Staff ID</th>
                                <th>Staff Name</th>
                                <th>Service ID</th>
                                <th>Check</th>
                            </tr>
                        </thead>
                        <tbody>
                            {AllreqData.length > 0 ? (
                                AllreqData.map((edreq) => (
                                    <tr key={edreq.id}>
                                        <td>{edreq.id}</td>
                                        <td>{edreq.staff}</td>
                                        <td>{edreq.staff_name}</td>
                                        <td>{edreq.service}</td>
                                        <td>
                                            <button className='unavareq-table-checkbut' onClick={() => setreqData(edreq)}>Check</button>
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="5">No requests available</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
            <div className="unavareq-r">
                <div className="unavareq-r-cont">
                    <p className="unavareq-details-title">Unavalabilty Request Details</p>
                    <div className="unavareq-details-box-cont">
                        {reqData ? (
                            <>
                                <DetailBox label="Staff ID" value={reqData.staff} />
                                <DetailBox label="Staff Name" value={reqData.staff_name} />
                                <DetailBox label="Service ID" value={reqData.service} />
                            </>
                        ) : <p>No Request Selected</p>}
                    </div>
                    <div>
                        <button className='unavareq-details-but' onClick={() => reqData && accept_req(reqData.id)}>
                            Approve And Reassign
                        </button>
                        <button className='unavareq-details-but-r' onClick={() => reqData && reject_req(reqData.id)}>Reject</button>
                    </div>
                </div>
            </div>
        </div>
    );
};

const DetailBox = ({ label, value }) => (
    <div className="unavareq-details-box">
        <p className="unavareq-details-key">{label}</p>
        <p className="unavareq-details-value">{value || ""}</p>
    </div>
);

export default UnavaReq;
