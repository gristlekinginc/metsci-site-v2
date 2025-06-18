import clsx from 'clsx';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

const InfoPanesList = [
  {
    title: 'MetSci Podcast',
    description: 'Learn LoRaWAN from industry experts.',
    link: 'https://pod.metsci.show',
    iconDark: '/img/icon_images/white-mic-transparent.png',
    iconLight: '/img/icon_images/orange-mic-transparent.png',
    buttonText: 'Listen Now'
  },
  {
    title: 'Console Access',
    description: 'Access the MeteoScientific Console.',
    link: 'https://console.meteoscientific.com',
    iconDark: '/img/icon_images/white-console-transparent.png',
    iconLight: '/img/icon_images/orange-console-transparent.png',
    buttonText: 'Open Console'
  },
  {
    title: 'MetSci Projects',
    description: 'Explore projects built by MeteoScientific.',
    link: 'https://sled.meteoscientific.com',
    iconDark: '/img/icon_images/white-sled-transparent.png',
    iconLight: '/img/icon_images/orange-sled-transparent.png',
    buttonText: 'View Projects'
  }
];

function InfoPane({title, description, link, iconDark, iconLight, buttonText}) {
  return (
    <div className={clsx('col col--4')}>
      <div className={styles.infoPane}>
        <div className={styles.infoPaneIcon}>
          <img 
            src={iconDark} 
            alt={title}
            className={styles.iconDark}
          />
          <img 
            src={iconLight} 
            alt={title}
            className={styles.iconLight}
          />
        </div>
        <h3 className={styles.infoPaneTitle}>{title}</h3>
        <p className={styles.infoPaneDescription}>{description}</p>
        <Link 
          to={link} 
          className={styles.infoPaneButton}
          target="_blank"
          rel="noopener noreferrer"
        >
          {buttonText}
        </Link>
      </div>
    </div>
  );
}

export default function InfoPanes() {
  return (
    <section className={styles.infoPanes}>
      <div className="container">
        <div className="row">
          {InfoPanesList.map((props, idx) => (
            <InfoPane key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
} 