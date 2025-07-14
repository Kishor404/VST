import '../styles/customer.css';
import { FaUsers } from "react-icons/fa";
import axios from 'axios';
import Cookies from 'js-cookie';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const Customer = () => {
    const [searchMode, setSearchMode] = useState("name"); // default search by name
    const [searchQuery, setSearchQuery] = useState("");
    const [customerList, setCustomerList] = useState([]);
    const [filteredList, setFilteredList] = useState([]);
    const [isCreating, setIsCreating] = useState(false);
    const [fetchData, setFetchData] = useState(null);
    const [newCustomer, setNewCustomer] = useState({
        name: "",
        phone: "",
        email: "",
        address: "",
        city: "",
        district: "",
        postal_code: "",
        region: Cookies.get('region') || "",
        role: "customer",
        password: "",
        confirm_password: "",
    });

    const refreshToken = Cookies.get('refresh_token');
    const headRegion = Cookies.get('region');

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
        const getAllCustomers = async () => {
            const accessToken = await refresh_token();
            if (!accessToken) return;
            try {
                const response = await axios.post(
                    "http://157.173.220.208/utils/getalluser/",
                    { role: 'customer', region: headRegion },
                    { headers: { Authorization: `Bearer ${accessToken}` } }
                );
                setCustomerList(response.data);
                setFilteredList(response.data); // Initially all customers shown
            } catch (error) {
                console.error("Error fetching customers:", error);
            }
        };
        getAllCustomers();
    }, []);

    // Filter function for the search
    useEffect(() => {
        if (!searchQuery.trim()) {
            setFilteredList(customerList);
            return;
        }

        const filtered = customerList.filter((customer) => {
            const fieldValue = (customer[searchMode] || "").toString().toLowerCase();
            return fieldValue.includes(searchQuery.toLowerCase());
        });

        setFilteredList(filtered);
    }, [searchQuery, searchMode, customerList]);

    const updateCustomer = async () => {
        const AT = await refresh_token();
        if (!fetchData) {
            alert("No customer selected to update");
            return;
        }
        const updatedData = { ...fetchData };

        axios.post("http://157.173.220.208/utils/edituserxxx/", updatedData, {
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${AT}`,
            },
        }).then(() => {
            alert("Customer updated successfully!");
        }).catch((error) => {
            console.error("Error updating customer:", error);
            alert("Failed to update customer");
        });
    };

    const createCustomer = async () => {
        const isAnyFieldEmpty = Object.entries(newCustomer).some(
            ([_, value]) => typeof value === "string" && value.trim() === ""
        );

        if (isAnyFieldEmpty) {
            alert("Please fill in all fields before creating the customer.");
            return;
        }

        if (newCustomer.password !== newCustomer.confirm_password) {
            alert("Password and Confirm Password do not match.");
            return;
        }

        axios
            .post("http://157.173.220.208/log/signup/", newCustomer, {
                headers: { "Content-Type": "application/json" },
            })
            .then(() => {
                alert("Customer created successfully!");
                setNewCustomer({
                    name: "",
                    phone: "",
                    email: "",
                    address: "",
                    city: "",
                    district: "",
                    postal_code: "",
                    region: headRegion,
                    role: "customer",
                    password: "",
                    confirm_password: "",
                });
                setIsCreating(false);
                setFilteredList(customerList); // Reset filtered list to all customers
                setSearchQuery(""); // Clear search input
            })
            .catch((error) => {
                console.error("Error creating customer:", error);
                alert("Failed to create customer");
            });
    };

    // When clicking a row, show details on right panel
    const selectCustomer = (customer) => {
        setFetchData(customer);
        setIsCreating(false);
    };

    // Show all customers and reset search
    const handleShowAll = () => {
        setFilteredList(customerList);
        setSearchQuery("");
        setIsCreating(false);
        setFetchData(null);
    };

    return (

            <div className="customer-cont">
                {/* CUSTOMER LEFT */}
                <div className="customer-left">
                    {/* Search dropdown, input, and buttons in one row */}
                    <div style={{ display: "flex", marginBottom: "10px", gap: "10px", alignItems: "center" }} className='customer-search-bar'>
                        <select
                            value={searchMode}
                            onChange={(e) => setSearchMode(e.target.value)}
                            className="customer-search-mode"
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
                            className="customer-name-search-input"
                        />

                        <button
                            className="customer-edit-button"
                            onClick={() => {
                                setIsCreating(true);
                                setFetchData(null);
                            }}
                        >
                            Add
                        </button>

                        <button
                            className="customer-edit-button"
                            onClick={handleShowAll}
                        >
                            Show All
                        </button>
                    </div>

                    {/* CUSTOMER LIST */}
                    <div className="customer-list-cont">
                        <table className="customer-list" style={{ width: "100%" }}>
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
                                            No customers found.
                                        </td>
                                    </tr>
                                ) : (
                                    filteredList.map((customer) => (
                                        <tr
                                            key={customer.id}
                                            style={{ cursor: "pointer" }}
                                            onClick={() => selectCustomer(customer)}
                                            className={fetchData?.id === customer.id ? "selected-row" : ""}
                                        >
                                            <td>{customer.id}</td>
                                            <td>{customer.name}</td>
                                            <td>{customer.phone}</td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* CUSTOMER RIGHT */}
                <div className="customer-right">
                    <div className="customer-count-cont">
                        <div className="customer-count-box">
                            <p className="customer-count-value">{filteredList.length}</p>
                            <p className="customer-count-title">Customers</p>
                        </div>
                        <FaUsers className="customer-count-icon" size={50} color="green" />
                    </div>
                    <div className="customer-details-cont">
                        <p className="customer-details-title">
                            {isCreating ? "Add New Customer" : fetchData ? "Customer Details" : "No Customer Selected"}
                        </p>
                        <div className="customer-details-box-cont">
                            {isCreating ? (
                                <>
                                    {Object.entries(newCustomer).map(([key, value]) => (
                                        <DetailBox
                                            key={key}
                                            label={key.replace("_", " ").charAt(0).toUpperCase() + key.replace("_", " ").slice(1)}
                                            value={value}
                                            field={key}
                                            setFetchData={(updater) =>
                                                setNewCustomer((prev) => ({ ...prev, [key]: updater(prev[key]) }))
                                            }
                                        />
                                    ))}
                                </>
                            ) : fetchData ? (
                                <>
                                    <DetailBox label="Name" value={fetchData.name} field="name" setFetchData={setFetchData} />
                                    <DetailBox label="Phone" value={fetchData.phone} field="phone" setFetchData={setFetchData} />
                                    <DetailBox label="Email" value={fetchData.email} field="email" setFetchData={setFetchData} />
                                    <DetailBox label="Region" value={fetchData.region} field="region" setFetchData={setFetchData} />
                                    <DetailBox label="Address" value={fetchData.address} field="address" setFetchData={setFetchData} />
                                    <DetailBox label="City" value={fetchData.city} field="city" setFetchData={setFetchData} />
                                    <DetailBox label="District" value={fetchData.district} field="district" setFetchData={setFetchData} />
                                    <DetailBox label="Postal Code" value={fetchData.postal_code} field="postal_code" setFetchData={setFetchData} />
                                    <DetailBox label="Role" value={fetchData.role} field="role" setFetchData={setFetchData} />
                                </>
                            ) : (
                                <p style={{ padding: "20px" }}>Select a customer to view/edit details.</p>
                            )}
                        </div>
                        {isCreating ? (
                            <button className="customer-details-but" onClick={createCustomer}>
                                Add Customer
                            </button>
                        ) : (
                            fetchData && (
                                <button className="customer-details-but" onClick={updateCustomer}>
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
    <div className="customer-details-box">
        <p className="customer-details-key">{label}</p>
        <input
            className="customer-details-value"
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

export default Customer;
