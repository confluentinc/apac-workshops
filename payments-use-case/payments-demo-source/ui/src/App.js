import React, { Component } from 'react';
import {Diagram} from './assets/Diagram.js';
import './App.css';
import axios from 'axios'

let demoServerHostname = 'localhost'

class App extends Component {
  constructor() {
    super();
    this.state = {
      transitActive: false,
      retailActive: false,
      tollActive: false,
      transactionActive: false,
      parkingActive: false
    }

    let transitInterval = setInterval(() => {
      if (this.state.transitActive) {
        axios.get(`http://${demoServerHostname}:3010/transit`)
      }
    }, 1000)

    let retailInterval = setInterval(() => {
      if (this.state.retailActive) {
        axios.get(`http://${demoServerHostname}:3010/retail`)
      }
    }, 1000)

    let tollInterval = setInterval(() => {
      if (this.state.tollActive) {
        axios.get(`http://${demoServerHostname}:3010/toll`)
      }
    }, 1000)

    let parkingInterval = setInterval(() => {
      if (this.state.parkingActive) {
        axios.get(`http://${demoServerHostname}:3010/parking`)
      }
    }, 1000)

    let transactionInterval = setInterval(() => {
      if (this.state.transactionActive) {
        axios.get(`http://${demoServerHostname}:3010/transaction`)
      }
    }, 1000)

  }

  render() {
    return (
      <div className="App">
          <Diagram
            transitClick={this.transitClick}
            transitClass={this.state.transitActive ? "active" : "inactive"}
            retailClick={this.retailClick}
            retailClass={this.state.retailActive ? "active" : "inactive"}
            tollClick={this.tollClick}
            tollClass={this.state.tollActive ? "active" : "inactive"}
            parkingClick={this.parkingClick}
            parkingClass={this.state.parkingActive ? "active" : "inactive"}
            transactionClick={this.transactionClick}
            transactionClass={this.state.transactionActive ? "active" : "inactive"}
          />
      </div>
    )
  }

  transitClick = () => {
    this.setState({transitActive: !this.state.transitActive})
  }

  retailClick = () => {
    this.setState({retailActive: !this.state.retailActive})
  }

  tollClick = () => {
    this.setState({tollActive: !this.state.tollActive})
  }

  parkingClick = () => {
    this.setState({parkingActive: !this.state.parkingActive})
  }

  transactionClick = () => {
    this.setState({transactionActive: !this.state.transactionActive})
  }

}

export default App;
