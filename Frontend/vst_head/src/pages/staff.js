
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/staff.css';
import { FaUsers } from "react-icons/fa";
import axios from 'axios';
import Cookies from 'js-cookie';

const Staff = () => {
    /* ------------------------------------------------------------------ */
        /* ───────────────────────────  ROUTING  ──────────────────────────── */
        /* ------------------------------------------------------------------ */
        const navigate = useNavigate();
    
        /** Redirect unauthenticated users to /head/ immediately. */
        useEffect(() => {
            const isLoggedIn = Cookies.get('Login') === 'True';
            if (!isLoggedIn) navigate('/head/');
        }, [navigate]);
    
    const [searchMode, setSearchMode] = useState("name"); // default search by name
    const [searchQuery, setSearchQuery] = useState("");
    const [staffList, setstaffList] = useState([]);
    const [filteredList, setFilteredList] = useState([]);
    const [isCreating, setIsCreating] = useState(false);
    const [fetchData, setFetchData] = useState(null);
    const [newstaff, setNewstaff] = useState({
        name: "",
        phone: "",
        address: "",
        city: "",
        district: "",
        postal_code: "",
        region: Cookies.get('region') || "",
        role: "worker",
        password: "",
        confirm_password: "",
    });

    const refreshToken = Cookies.get('refresh_token');
    const headRegion = Cookies.get('region');

    const refresh_token = async () => {
        try {
            const res = await axios.post(
                "http://157.173.220.208/log/token/refresh/",
                { refresh: refreshToken },
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            return null;
        }
    };

    useEffect(() => {
        const getAllstaffs = async () => {
            const accessToken = await refresh_token();
            if (!accessToken) return;
            try {
                const response = await axios.post(
                    "http://157.173.220.208/utils/getalluser/",
                    { role: 'worker', region: headRegion },
                    { headers: { Authorization: `Bearer ${accessToken}` } }
                );
                setstaffList(response.data);
                setFilteredList(response.data); // Initially all staffs shown
            } catch (error) {
                console.error("Error fetching staffs:", error);
            }
        };
        getAllstaffs();
    }, []);

    // Filter function for the search
    useEffect(() => {
        if (!searchQuery.trim()) {
            setFilteredList(staffList);
            return;
        }

        const filtered = staffList.filter((staff) => {
            const fieldValue = (staff[searchMode] || "").toString().toLowerCase();
            return fieldValue.includes(searchQuery.toLowerCase());
        });

        setFilteredList(filtered);
    }, [searchQuery, searchMode, staffList]);

    const updatestaff = async () => {
        const AT = await refresh_token();
        if (!fetchData) {
            alert("No staff selected to update");
            return;
        }
        const updatedData = { ...fetchData };

        axios.post("http://157.173.220.208/utils/edituserxxx/", updatedData, {
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${AT}`,
            },
        }).then(() => {
            alert("staff updated successfully!");
        }).catch((error) => {
            console.error("Error updating staff:", error);
            alert("Failed to update staff");
        });
    };

    const createstaff = async () => {
        const isAnyFieldEmpty = Object.entries(newstaff).some(
            ([_, value]) => typeof value === "string" && value.trim() === ""
        );

        if (isAnyFieldEmpty) {
            alert("Please fill in all fields before creating the staff.");
            return;
        }

        if (newstaff.password !== newstaff.confirm_password) {
            alert("Password and Confirm Password do not match.");
            return;
        }

        axios
            .post("http://157.173.220.208/log/signup/", newstaff, {
                headers: { "Content-Type": "application/json" },
            })
            .then(() => {
                alert("staff created successfully!");
                setNewstaff({
                    name: "",
                    phone: "",
                    address: "",
                    city: "",
                    district: "",
                    postal_code: "",
                    region: headRegion,
                    role: "worker",
                    password: "",
                    confirm_password: "",
                });
                setIsCreating(false);
                setFilteredList(staffList); // Reset filtered list to all staffs
                setSearchQuery(""); // Clear search input
            })
            .catch((error) => {
                console.error("Error creating staff:", error);
                alert("Failed to create staff");
            });
    };

    // When clicking a row, show details on right panel
    const selectstaff = (staff) => {
        setFetchData(staff);
        setIsCreating(false);
    };

    // Show all staffs and reset search
    const handleShowAll = () => {
        setFilteredList(staffList);
        setSearchQuery("");
        setIsCreating(false);
        setFetchData(null);
    };

    return (

            <div className="staff-cont">
                {/* staff LEFT */}
                <div className="staff-left">
                    {/* Search dropdown, input, and buttons in one row */}
                    <div style={{ display: "flex", marginBottom: "10px", gap: "10px", alignItems: "center" }} className='staff-search-bar'>
                        <select
                            value={searchMode}
                            onChange={(e) => setSearchMode(e.target.value)}
                            className="staff-search-mode"
                            style={{ padding: "5px", minWidth: "140px" }}
                        >
                            <option value="name">Search by Name</option>
                            <option value="phone">Search by Phone</option>
                            <option value="id">Search by ID</option>
                        </select>

                        <input
                            type="text"
                            placeholder={`Search by ${searchMode.charAt(0).toUpperCase() + searchMode.slice(1)}`}
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="staff-name-search-input"
                        />

                        <button
                            className="staff-edit-button"
                            onClick={() => {
                                setIsCreating(true);
                                setFetchData(null);
                            }}
                        >
                            Add
                        </button>

                        <button
                            className="staff-edit-button"
                            onClick={handleShowAll}
                        >
                            Show All
                        </button>
                    </div>

                    {/* staff LIST */}
                    <div className="staff-list-cont">
                        <table className="staff-list" style={{ width: "100%" }}>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Name</th>
                                    <th>Phone</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredList.length === 0 ? (
                                    <tr>
                                        <td colSpan={3} style={{ textAlign: "center", padding: "10px" }}>
                                            No staffs found.
                                        </td>
                                    </tr>
                                ) : (
                                    filteredList.map((staff) => (
                                        <tr
                                            key={staff.id}
                                            style={{ cursor: "pointer" }}
                                            onClick={() => selectstaff(staff)}
                                            className={fetchData?.id === staff.id ? "selected-row" : ""}
                                        >
                                            <td>{staff.id}</td>
                                            <td>{staff.name}</td>
                                            <td>{staff.phone}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* staff RIGHT */}
                <div className="staff-right">
                    <div className="staff-count-cont">
                        <div className="staff-count-box">
                            <p className="staff-count-value">{filteredList.length}</p>
                            <p className="staff-count-title">staffs</p>
                        </div>
                        <FaUsers className="staff-count-icon" size={50} color="green" />
                    </div>
                    <div className="staff-details-cont">
                        <p className="staff-details-title">
                            {isCreating ? "Add New staff" : fetchData ? "staff Details" : "No staff Selected"}
                        </p>
                        <div className="staff-details-box-cont">
                            {isCreating ? (
                                <>
                                    {Object.entries(newstaff).map(([key, value]) => (
                                        <DetailBox
                                            key={key}
                                            label={key.replace("_", " ").charAt(0).toUpperCase() + key.replace("_", " ").slice(1)}
                                            value={value}
                                            field={key}
                                            setFetchData={(updater) =>
                                                setNewstaff((prev) => ({ ...prev, [key]: updater(prev[key]) }))
                                            }
                                        />
                                    ))}
                                </>
                            ) : fetchData ? (
                                <>
                                    <DetailBox label="Name" value={fetchData.name} field="name" setFetchData={setFetchData} />
                                    <DetailBox label="Phone" value={fetchData.phone} field="phone" setFetchData={setFetchData} />
                                    <DetailBox label="Region" value={fetchData.region} field="region" setFetchData={setFetchData} />
                                    <DetailBox label="Address" value={fetchData.address} field="address" setFetchData={setFetchData} />
                                    <DetailBox label="City" value={fetchData.city} field="city" setFetchData={setFetchData} />
                                    <DetailBox label="District" value={fetchData.district} field="district" setFetchData={setFetchData} />
                                    <DetailBox label="Postal Code" value={fetchData.postal_code} field="postal_code" setFetchData={setFetchData} />
                                    <DetailBox label="Role" value={fetchData.role} field="role" setFetchData={setFetchData} />
                                </>
                            ) : (
                                <p style={{ padding: "20px" }}>Select a staff to view/edit details.</p>
                            )}
                        </div>
                        {isCreating ? (
                            <button className="staff-details-but" onClick={createstaff}>
                                Add staff
                            </button>
                        ) : (
                            fetchData && (
                                <button className="staff-details-but" onClick={updatestaff}>
                                    Update
                                </button>
                            )
                        )}
                    </div>
                </div>
            </div>
    );
};

// DetailBox Component
const DetailBox = ({ label, value, field, setFetchData }) => (
    <div className="staff-details-box">
        <p className="staff-details-key">{label}</p>
        <input
            className="staff-details-value"
            value={value || ""}
            onChange={(e) =>
                setFetchData((prevVal) =>
                    typeof prevVal === "object"
                        ? { ...prevVal, [field]: e.target.value }
                        : e.target.value
                )
            }
        />
    </div>
);

export default Staff;
