import React, { Component } from 'react';
import Navigation from './Navigation';
import SongList from './SongList';
import './index.css'

class App extends Component {
  render() {
    return (
      <div>
        <Navigation/>
        <div className='container'>
          <p className='text-muted'>Add your favorite songs here so we can play them from our awesome jukebox! You'll need a YouTube video link for the song.</p>
          <p className='text-muted'>Press thumbnail to play. Use the arrows to vote.</p>
          <SongList />
        </div>
        <footer className="footer">
           <div className="container">
             <p className="text-muted small">© 2016 Whynauts Camp Organization Limited Partnership</p>
           </div>
         </footer>
      </div>
    );
  }
}

export default App;
