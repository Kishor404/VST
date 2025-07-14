import '../styles/essentials.css';
import { FaUsersGear } from "react-icons/fa6";
import { TiWarning } from "react-icons/ti";
import { FaUserCheck } from "react-icons/fa";
import { FaUserTag } from "react-icons/fa";
import axios from 'axios';
import Cookies from 'js-cookie';
import { Link } from 'react-router-dom';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable'; // ✅ Correct import
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const Essentials = () => {
    const refreshToken = Cookies.get('refresh_token');
    const [pendingCount, setPendingCount] = useState(0);
    const [dataList, setDataList] = useState([]);
    const [warrentyList, setWarrentyList] = useState([]);
    const [ACMList, setACMList] = useState([]);
    const [ContractList, setContractList] = useState([]);
    const [cards, setCards] = useState([]);
    const [selectedMonth, setSelectedMonth] = useState("");

    /* ------------------------------------------------------------------ */
        /* ───────────────────────────  ROUTING  ──────────────────────────── */
        /* ------------------------------------------------------------------ */
        const navigate = useNavigate();
    
        /** Redirect unauthenticated users to /head/ immediately. */
        useEffect(() => {
            const isLoggedIn = Cookies.get('Login') === 'True';
            if (!isLoggedIn) navigate('/head/');
        }, [navigate]);
    

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

    const getPendingCount = async () => {
        const accessToken = await refresh_token();
        if (!accessToken) return;
        try {
            const response = await axios.get("http://157.173.220.208/utils/getservicebyhead/", { headers: { Authorization: `Bearer ${accessToken}` } });
            setPendingCount(response.data.filter((service) => service.status === "BD" && service.staff_name === "Waiting...").length);
        } catch (error) {
            console.error("Error fetching customers:", error);
        }
    };

    const getAllCards = async () => {
        const accessToken = await refresh_token();
        if (!accessToken) return;
        try {
            const response = await axios.get("http://157.173.220.208/api/headcardlist/", { headers: { Authorization: `Bearer ${accessToken}` } });
            setCards(response.data);
            return response.data;
        } catch (error) {
            console.error("Error fetching customers:", error);
        }
    };

    const getWarranty = async () => {
        const data = [];
        const today = new Date();
        const card = await getAllCards();

        for (let i = 0; i < card.length; i++) {
            const startDate = new Date(card[i].warranty_start_date);
            const endDate = new Date(card[i].warranty_end_date);
            if (startDate && endDate && startDate <= today && endDate >= today) {
                const serviceDates = [];
                const current = new Date(startDate);
                while (current <= endDate) {
                    serviceDates.push(new Date(current));
                    current.setMonth(current.getMonth() + 4);
                }
                card[i].service_schedule = serviceDates;
                card[i].start = card[i].warranty_start_date;
                card[i].end = card[i].warranty_end_date;
                data.push(card[i]);
            }
        }
        setWarrentyList(data);
        return data;
    };

    const setWarranty = async () => {
        const data = await getWarranty();
        setDataList(data);
    };

    const getACM = async () => {
        const data = [];
        const today = new Date();
        const card = await getAllCards();
        for (let i = 0; i < card.length; i++) {
            const startDate = new Date(card[i].acm_start_date);
            const endDate = new Date(card[i].acm_end_date);
            if (startDate && endDate && startDate <= today && endDate >= today) {
                card[i].end = card[i].acm_end_date;
                card[i].start = card[i].acm_start_date;
                data.push(card[i]);
            }
        }
        setACMList(data);
        return data;
    };

    const setACM = async () => {
        const data = await getACM();
        setDataList(data);
    };

    const getContract = async () => {
        const data = [];
        const today = new Date();
        const card = await getAllCards();
        for (let i = 0; i < card.length; i++) {
            const startDate = new Date(card[i].contract_start_date);
            const endDate = new Date(card[i].contract_end_date);
            if (startDate && endDate && startDate <= today && endDate >= today) {
                card[i].end = card[i].contract_end_date;
                card[i].start = card[i].contract_start_date;
                data.push(card[i]);
            }
        }
        setContractList(data);
        return data;
    };

    const setContract = async () => {
        const data = await getContract();
        setDataList(data);
    };

    const filterWarrantyByMonth = (monthYear) => {
        if (!monthYear) return;
        const [month, year] = monthYear.split('-').map(Number);
        const filtered = warrentyList.filter(item =>
            item.service_schedule.some(date =>
                new Date(date).getMonth() + 1 === month &&
                new Date(date).getFullYear() === year
            )
        );
        setDataList(filtered);
    };

    const generatePDF = () => {
        const doc = new jsPDF();
        doc.setFontSize(18);
        doc.text('Free Service For Warranty Customer Report', 14, 22);

        const tableColumn = ["ID", "Customer", "Model", "Start", "End", "Service Dates"];
        const tableRows = [];

        dataList.forEach(data => {
            const rowData = [
                data.id,
                `${data.customer_name} (${data.customer_code})`,
                data.model,
                data.start,
                data.end,
                data.service_schedule?.map(date =>
                    new Date(date).toLocaleDateString()
                ).join(", ") || "N/A"
            ];
            tableRows.push(rowData);
        });

        autoTable(doc, {
            startY: 30,
            head: [tableColumn],
            body: tableRows,
            styles: { fontSize: 8 },
        });

        doc.save(`Customer_Report_${new Date().toISOString().split("T")[0]}.pdf`);
    };

    useEffect(() => {
        getPendingCount();
        getAllCards();
        getWarranty();
        getACM();
        getContract();
    }, []);

    useEffect(() => {
        if (selectedMonth) {
            filterWarrantyByMonth(selectedMonth);
        }
    }, [selectedMonth]);

    return (
        <section className="es-body">
            <div className="es-top-cont">
                <div className="es-top-card-cont">
                    <Link className="es-top-card" to='/head/service'>
                        <div className="es-top-card-left">
                            <p className="es-top-card-value">{pendingCount}</p>
                            <p className="es-top-card-title">Action Required</p>
                        </div>
                        <TiWarning className="es-top-card-icon" size={50} color='red' />
                    </Link>
                    <div className="es-top-card" onClick={setWarranty}>
                        <div className="es-top-card-left">
                            <p className="es-top-card-value">{warrentyList.length}</p>
                            <p className="es-top-card-title">Warranty Customer</p>
                        </div>
                        <FaUserCheck className="es-top-card-icon" size={40} color='green' />
                    </div>
                    <div className="es-top-card" onClick={setACM}>
                        <div className="es-top-card-left">
                            <p className="es-top-card-value">{ACMList.length}</p>
                            <p className="es-top-card-title">ACM Customer</p>
                        </div>
                        <FaUserTag className="es-top-card-icon" size={40} color='navy' />
                    </div>
                    <div className="es-top-card" onClick={setContract}>
                        <div className="es-top-card-left">
                            <p className="es-top-card-value">{ContractList.length}</p>
                            <p className="es-top-card-title">On Contract</p>
                        </div>
                        <FaUsersGear className="es-top-card-icon" size={50} color='purple' />
                    </div>
                </div>
            </div>

            <div className="es-main-cont">
                
                <div className='es-fliter-box'>
                    
                    <div className="es-filter-cont">
                        <label>Select Month for Free Service</label>
                        <select onChange={(e) => setSelectedMonth(e.target.value)} value={selectedMonth}>
                            <option value="">-- Select Month --</option>
                            {Array.from({ length: 6 }, (_, i) => {
                                const date = new Date();
                                date.setMonth(date.getMonth() + i);
                                const month = date.getMonth() + 1;
                                const year = date.getFullYear();
                                return (
                                    <option key={`${month}-${year}`} value={`${month}-${year}`}>
                                        {date.toLocaleString('default', { month: 'long' })} {year}
                                    </option>
                                );
                            })}
                        </select>
                    </div>
                    <div className='es-gen'>
                        <button className="es-report-button" onClick={generatePDF}>Generate Report</button>
                    </div>
                </div>

                

                <div className="es-main-table-cont">
                    <table className="es-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Customer</th>
                                <th>Model</th>
                                <th>Start</th>
                                <th>End</th>
                                <th>Service Dates</th>
                            </tr>
                        </thead>
                        <tbody>
                            {dataList.map((data) => (
                                <tr key={data.id}>
                                    <td>{data.id}</td>
                                    <td>{data.customer_name + " ( " + data.customer_code + " )"}</td>
                                    <td>{data.model}</td>
                                    <td>{data.start}</td>
                                    <td>{data.end}</td>
                                    <td>
                                        {data.service_schedule &&
                                            data.service_schedule.map(date =>
                                                new Date(date).toLocaleDateString()
                                            ).join(", ")}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </section>
    );
};

export default Essentials;
